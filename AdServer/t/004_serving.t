use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestDatabase;
use AdServer;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use URI;
use Digest::MD5 qw(md5_hex);
use JSON::PP qw(decode_json);

my $schema = TestDatabase->schema;
my $app = AdServer->to_app;
# Make the address deterministic without relying on a network listener.
my $test = Plack::Test->create(sub {
    my $env = shift;
    $env->{REMOTE_ADDR} = '192.0.2.10';
    return $app->($env);
});
my $client = $schema->resultset('Client')->create({code => 'client', name => 'Client'});
my $campaign = $client->add_to_campaigns({code => 'campaign', name => 'Campaign'});
my $other = $client->add_to_campaigns({code => 'other', name => 'Other'});
my $empty = $client->add_to_campaigns({code => 'empty', name => 'Empty'});
my $empty_client = $schema->resultset('Client')->create({code => 'empty', name => 'Empty'});

sub make_ad {
    my ($parent, $code) = @_;
    return $parent->add_to_ads({code => $code, name => $code,
        heading => "Heading $code", body_text => "Body $code", image => 'test.png',
        url => "https://advertiser.example/$code?source=ad#offer"});
}
my $ad = make_ad($campaign, 'one');
my $second = make_ad($campaign, 'two');
my $third = make_ad($other, 'three');
my $foreign_client = $schema->resultset('Client')->create({code => 'foreign', name => 'Foreign'});
my $foreign_campaign = $foreign_client->add_to_campaigns({code => 'campaign', name => 'Foreign campaign'});
my $foreign_ad = make_ad($foreign_campaign, 'one');
is($ad->hash, md5_hex('client:campaign:one'), 'Insert generates the expected click identifier');

my $base = '/client/client';
my $campaign_path = "$base/campaign/campaign";
my $exact = "$campaign_path/ad/one";
my $referer = 'https://publisher.example/story?a=1&b=two+words#section';

sub count { $schema->resultset(shift)->count }
sub serve {
    my ($path, @eligible) = @_;
    my $before = count('Impression');
    my $clicks = count('Click');
    my $res = $test->request(GET $path, Referer => $referer, 'User-Agent' => 'AdServer integration test');
    is($res->code, 200, "$path serves successfully");
    is(count('Impression'), $before + 1, 'Exactly one impression recorded');
    is(count('Click'), $clicks, 'Serving does not record a click');
    my $row = $schema->resultset('Impression')->search({}, {order_by => {-desc => 'id'}})->first;
    ok(scalar(grep { $_->id == $row->ad_id } @eligible), 'Selected ad belongs to the eligible set');
    is($row->referer, $referer, 'Publisher referer recorded');
    is($row->ip_addr, '192.0.2.10', 'Request IP recorded');
    is($row->user_agent, 'AdServer integration test', 'User agent recorded');
    ok($row->get_column('timestamp'), 'Database supplies impression timestamp');
    like($res->decoded_content, qr/\Q@{[$row->ad->heading]}\E/, 'Rendered heading matches recorded ad');
    return $res;
}
sub missing {
    my ($path) = @_;
    my @before = (count('Impression'), count('Click'));
    is($test->request(GET $path)->code, 404, "$path returns 404");
    is_deeply([count('Impression'), count('Click')], \@before, 'Rejected request records no events');
}
sub click {
    my ($url, $expected_referer, $expected_impression) = @_;
    my $before = count('Click');
    my $impressions = count('Impression');
    my $res = $test->request(GET $url);
    is($res->code, 302, 'Click redirects');
    is($res->header('Location'), $ad->url, 'Exact advertiser URL preserved');
    is(count('Click'), $before + 1, 'Exactly one click recorded');
    is(count('Impression'), $impressions, 'Click does not record an impression');
    my $row = $schema->resultset('Click')->search({}, {order_by => {-desc => 'id'}})->first;
    is($row->ad_id, $ad->id, 'Click belongs to the advertised ad');
    is($row->referer, $expected_referer, 'Click attribution preserved');
    is($row->impression_id, $expected_impression, 'Click links only to the expected impression');
    ok($row->get_column('timestamp'), 'Database supplies click timestamp');
}

subtest 'Serving and following both rendered links' => sub {
    my $res = serve($exact, $ad);
    my @links = $res->decoded_content =~ /<a\b[^>]*\bhref="([^"]*)"/g;
    is(scalar @links, 2, 'Image and text each provide a click link');
    my $impression = $schema->resultset('Impression')->search({}, {order_by => {-desc => 'id'}})->first;
    like($impression->token, qr/\A[0-9a-f]{32}\z/, 'Impression has an opaque token');
    click($_, $referer, $impression->id) for @links;
    click($links[0] . '&referer=forged', $referer, $impression->id);
    my $legacy = URI->new('/ad/' . $ad->hash);
    $legacy->query_form(referer => $referer);
    click($legacy, $referer);
    click('/ad/' . $ad->hash . '?impression=' . $_ . '&referer=forged', undef)
        for '', 'invalid', ('0' x 32), ('A' x 32), ('a' x 33);
    my $foreign_impression = $foreign_ad->add_to_impressions({token => 'f' x 32, referer => 'Foreign'});
    click('/ad/' . $ad->hash . '?impression=' . $foreign_impression->token, undef);
    serve($exact, $ad);
    my $latest = $schema->resultset('Impression')->search({}, {order_by => {-desc => 'id'}})->first;
    isnt($latest->token, $impression->token, 'Each serving gets a new token');
    click('/ad/' . $ad->hash, undef);
};

subtest 'Selection and live filtering' => sub {
    # Assert membership, not a random distribution: these tests cannot flake on luck.
    serve($campaign_path, $ad, $second);
    serve($base, $ad, $second, $third);
    $campaign->update({is_live => 0});
    serve($base, $third);
    $campaign->update({is_live => 1});
    $second->update({is_live => 0});
    $other->update({is_live => 0});
    serve($campaign_path, $ad);
    serve($base, $ad);
    missing("$campaign_path/ad/two");
    missing('/ad/' . $second->hash);
    missing("$base/campaign/other");
    missing("$base/campaign/other/ad/three");
    $ad->update({is_live => 0});
    missing('/ad/' . $ad->hash);
    missing($exact);
    missing($campaign_path);
    missing($base);
    $ad->update({is_live => 1});
};

subtest 'Missing records and empty collections' => sub {
    missing($_) for '/client/missing', '/client/missing/campaign/campaign',
        '/client/missing/campaign/campaign/ad/one', "$base/campaign/missing",
        "$base/campaign/missing/ad/one", "$campaign_path/ad/missing",
        '/ad/missing', '/client/empty', "$base/campaign/empty";
};

subtest 'Disabled parents block serving but retain existing click behavior' => sub {
    $campaign->update({is_live => 0});
    missing($_) for $base, $campaign_path, $exact;
    click('/ad/' . $ad->hash, undef);
    $campaign->update({is_live => 1});
    $client->update({is_live => 0});
    missing($_) for $base, $campaign_path, $exact;
    click('/ad/' . $ad->hash, undef);
    $client->update({is_live => 1});
};

subtest 'Absent request metadata uses serving fallbacks' => sub {
    my $res = $test->request(GET $exact);
    is($res->code, 200, 'Ad serves without referer or user agent');
    my $row = $schema->resultset('Impression')->search({}, {order_by => {-desc => 'id'}})->first;
    is($row->referer, 'Unknown referer', 'Missing referer has the documented fallback');
    is($row->user_agent, 'Unknown UA', 'Missing user agent has the documented fallback');
    click('/ad/' . $ad->hash . '?impression=' . $row->token, 'Unknown referer', $row->id);
};

subtest 'Client listing includes only live clients' => sub {
    $foreign_client->update({is_live => 0});
    my @before = (count('Impression'), count('Click'));
    my $res = $test->request(GET '/client');
    is($res->code, 200, 'Client listing succeeds');
    my $data = decode_json($res->decoded_content);
    is_deeply([sort map { $_->{code} } @{$data->{clients}}],
        ['client', 'empty'], 'Disabled client excluded');
    is_deeply([count('Impression'), count('Click')], \@before, 'Listing records no events');
};

done_testing;
