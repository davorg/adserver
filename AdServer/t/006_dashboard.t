use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestDatabase;
use AdServer;
use AdServer::Model;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP qw(decode_json);

my $schema = TestDatabase->schema;
my $model = AdServer::Model->new(schema => $schema);
my $test = Plack::Test->create(AdServer->to_app);
my $empty = $test->request(GET '/dashboard');
is($empty->code, 200, 'Dashboard accessible without authentication');
like($empty->decoded_content, qr/No ads yet/, 'Empty dashboard is useful');
is($empty->header('Cache-Control'), 'no-store', 'Dashboard does not cache old figures');
is($model->dashboard_stats->{ctr}, '0.00', 'Empty CTR avoids division by zero');
subtest 'Dashboard URLs remain same-origin behind HTTPS proxies' => sub {
    like($empty->decoded_content, qr{data-endpoint="/dashboard/graph"},
        'HTTP backend emits a scheme-free JSON endpoint');
    like($empty->decoded_content, qr{src="/javascripts/dashboard.js"},
        'HTTP backend emits a scheme-free script URL');
    my $app = AdServer->to_app;
    my $mounted = Plack::Test->create(sub {
        my $env = shift;
        $env->{SCRIPT_NAME} = '/ads';
        $env->{PATH_INFO} = '/dashboard';
        return $app->($env);
    });
    my $res = $mounted->request(GET 'http://internal.example/ads/dashboard');
    is($res->code, 200, 'Dashboard works under a mount path');
    like($res->decoded_content, qr{data-endpoint="/ads/dashboard/graph"},
        'JSON endpoint preserves the mount path');
    like($res->decoded_content, qr{src="/ads/javascripts/dashboard.js"},
        'Script URL preserves the mount path');
};

my $dbh = $schema->storage->dbh;
$dbh->do(q{INSERT INTO client (id, code, name) VALUES (1, 'test', '<script>client</script>')});
$dbh->do(q{INSERT INTO campaign (id, code, name, client_id) VALUES (1, 'test', 'Campaign', 1)});
for my $id (1, 2) {
    $dbh->do(q{INSERT INTO ad (id, code, name, url, heading, body_text, hash, campaign_id)
      VALUES (?, ?, ?, 'https://example.test/', 'Heading', 'Body', ?, 1)},
      undef, $id, "ad$id", "Ad $id", "$id" x 32);
}
$dbh->do('INSERT INTO impression (ad_id) VALUES (1)') for 1 .. 3;
$dbh->do('INSERT INTO click (ad_id) VALUES (1)') for 1 .. 2;
my $stats = $model->dashboard_stats;
is($stats->{impressions}, 3, 'Total impressions');
is($stats->{clicks}, 2, 'Total clicks');
is($stats->{ctr}, '66.67', 'Overall CTR rounded to two places');
is($stats->{serving_count}, 2, 'Both ads initially serving');
is_deeply([map { [$_->{impressions}, $_->{clicks}, $_->{ctr}] } @{$stats->{ads}}],
    [[3, 2, '66.67'], [0, 0, '0.00']], 'Event counts do not multiply and zero-event ads remain visible');
$dbh->do('UPDATE campaign SET is_live = 0 WHERE id = 1');
is($model->dashboard_stats->{serving_count}, 0, 'Disabled parent makes ads inactive');
is($model->dashboard_stats->{ad_count}, 2, 'Inactive ads remain listed');
$dbh->do('INSERT INTO click (ad_id) VALUES (NULL)');
is($model->dashboard_stats->{clicks}, 3, 'Unassigned historical events included in totals');
my $res = $test->request(GET '/dashboard');
like($res->decoded_content, qr/&lt;script&gt;client&lt;\/script&gt;/, 'Names escaped');
unlike($res->decoded_content, qr/<script>/, 'No injected script markup');
like($res->decoded_content, qr/Inactive/, 'Inactive status displayed');
is($schema->resultset('Impression')->count, 3, 'Dashboard does not record impressions');
is($schema->resultset('Click')->count, 3, 'Dashboard does not record clicks');
subtest 'Daily graph and filters' => sub {
    $dbh->do("UPDATE impression SET timestamp = '2026-09-01 12:00:00'");
    $dbh->do("UPDATE click SET timestamp = '2026-09-03 23:59:59'");
    $dbh->do("INSERT INTO impression (ad_id, timestamp) VALUES (2, '2026-09-03 00:00:00')");
    $dbh->do("INSERT INTO impression (ad_id, timestamp) VALUES (2, '2026-09-04 00:00:00')");
    my %range = (from => '2026-09-01', to => '2026-09-03');
    my $graph = $model->dashboard_graph(%range);
    is_deeply([map { $_->{count} } @{$graph->{points}}], [3, 0, 1], 'Daily buckets include zeros and exclude next day');
    is($graph->{total}, 4, 'Total in range');
    for my $scope ('client:1', 'campaign:1', 'ad:1') {
        my $filtered = $model->dashboard_graph(%range, scope => $scope);
        is($filtered->{total}, $scope eq 'ad:1' ? 3 : 4, "$scope includes inactive historical records");
    }
    is($model->dashboard_graph(%range, scope => 'ad:2')->{total}, 1, 'Single ad excludes other ads');
    is($model->dashboard_graph(%range, metric => 'clicks')->{total}, 3, 'All clicks include unassigned history');
    is($model->dashboard_graph(%range, metric => 'clicks', scope => 'client:1')->{total}, 2, 'Client scope excludes unassigned clicks');
    $dbh->do("INSERT INTO client (id, code, name) VALUES (2, 'other', 'Other client')");
    $dbh->do("INSERT INTO campaign (id, code, name, client_id) VALUES (2, 'other', 'Other campaign', 2), (3, 'second', 'Second campaign', 1)");
    for my $id (3, 4) {
        $dbh->do(q{INSERT INTO ad (id, code, name, url, heading, body_text, hash, campaign_id)
          VALUES (?, ?, ?, 'https://example.test/', 'Heading', 'Body', ?, ?)},
          undef, $id, "ad$id", "Ad $id", "$id" x 32, $id - 1);
        $dbh->do("INSERT INTO impression (ad_id, timestamp) VALUES (?, '2026-09-03 12:00:00')", undef, $id);
    }
    is($model->dashboard_graph(%range)->{total}, 6, 'All scope includes multiple clients and campaigns');
    is($model->dashboard_graph(%range, scope => 'client:1')->{total}, 5, 'Client scope includes its campaigns but excludes another client');
    is($model->dashboard_graph(%range, scope => 'campaign:1')->{total}, 4, 'Campaign scope excludes a sibling campaign');
    my $single = $model->dashboard_graph(from => '2026-09-02', to => '2026-09-02');
    is(scalar @{$single->{points}}, 1, 'Single day is supported');
    is($single->{total}, 0, 'Empty day is zero');
    my $res = $test->request(GET '/dashboard/graph?metric=clicks&scope=ad:1&from=2026-09-01&to=2026-09-03');
    is($res->code, 200, 'Filtered chart renders');
    like($res->header('Content-Type'), qr{^application/json}, 'Graph endpoint returns JSON');
    my $data = decode_json($res->decoded_content);
    is($data->{metric}, 'clicks', 'Metric selection returned');
    is($data->{scope}, 'ad:1', 'Scope selection returned');
    is_deeply([map { $_->{count} } @{$data->{points}}], [0, 0, 2], 'JSON contains daily counts');
    ok(!exists $data->{line} && !exists $data->{points}[0]{x}, 'Server sends data, not rendering coordinates');
    my $page = $test->request(GET '/dashboard');
    like($page->decoded_content, qr{javascripts/dashboard.js}, 'Page loads client renderer');
    unlike($page->decoded_content, qr/<svg|<polyline/, 'Graph is not rendered on the server');
    for my $query ('metric=bad', 'scope=ad:9999', 'scope=client:1%20OR%201=1',
                   'from=2026-02-30', 'from=2026-09-03&to=2026-09-01',
                   'from=2020-01-01&to=2026-09-01') {
        is($test->request(GET '/dashboard/graph?' . $query)->code, 400, 'Invalid graph input is rejected');
    }
};
done_testing;
