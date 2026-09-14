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

my $schema = TestDatabase->schema;
my $model = AdServer::Model->new(schema => $schema);
my $test = Plack::Test->create(AdServer->to_app);
my $empty = $test->request(GET '/dashboard');
is($empty->code, 200, 'Dashboard accessible without authentication');
like($empty->decoded_content, qr/No ads yet/, 'Empty dashboard is useful');
is($empty->header('Cache-Control'), 'no-store', 'Dashboard does not cache old figures');
is($model->dashboard_stats->{ctr}, '0.00', 'Empty CTR avoids division by zero');
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
done_testing;
