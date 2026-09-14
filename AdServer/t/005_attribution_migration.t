use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestDatabase;
use Test::More;

my $dbh = TestDatabase->schema->storage->dbh;
sub apply_sql {
    my ($name) = @_;
    open my $fh, '<', "$FindBin::Bin/../../db/$name" or die $!;
    my $sql = do { local $/; <$fh> };
    $dbh->do($_) for grep /\S/, split /;/, $sql;
}

# Recreate the pre-migration shape with historical tracking data.
apply_sql('unpatch_5.sql');
$dbh->do("INSERT INTO impression (referer) VALUES ('Historical publisher')");
$dbh->do("INSERT INTO click (referer) VALUES ('Historical click')");
apply_sql('patch_5.sql');
is_deeply($dbh->selectrow_arrayref('SELECT referer, token FROM impression'),
    ['Historical publisher', undef], 'Migration preserves historical impressions');
is_deeply($dbh->selectrow_arrayref('SELECT referer, impression_id FROM click'),
    ['Historical click', undef], 'Migration preserves historical clicks');
$dbh->do("INSERT INTO impression (referer) VALUES ('Old application writer')");
is($dbh->selectrow_array('SELECT COUNT(*) FROM impression WHERE token IS NULL'),
    2, 'Old writers can insert multiple impressions without tokens');
my $token = 'a' x 32;
$dbh->do('INSERT INTO impression (token) VALUES (?)', undef, $token);
my $id = $dbh->last_insert_id(undef, undef, 'impression', undef);
$dbh->do('INSERT INTO click (impression_id) VALUES (?)', undef, $id);
local $dbh->{PrintError} = 0;
ok(!eval { $dbh->do('INSERT INTO impression (token) VALUES (?)', undef, $token); 1 },
    'Database rejects duplicate tokens');
ok(!eval { $dbh->do('INSERT INTO click (impression_id) VALUES (-1)'); 1 },
    'Database rejects nonexistent impression references');
apply_sql('unpatch_5.sql');
is($dbh->selectrow_array('SELECT COUNT(*) FROM click'), 2, 'Rollback preserves click rows');
is($dbh->selectrow_array('SELECT COUNT(*) FROM impression'), 3, 'Rollback preserves impression rows');
apply_sql('patch_5.sql');
is($dbh->selectrow_array('SELECT COUNT(*) FROM impression WHERE token IS NULL'), 3,
    'Migration can be reapplied after rollback');
done_testing;
