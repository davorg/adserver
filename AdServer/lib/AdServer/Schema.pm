use utf8;
package AdServer::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-11-27 16:03:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CIK1fdgHpO6iBswgZvQqBw

sub get_schema {
  my @errors;
  foreach (qw[ADSERVER_DB_HOST ADSERVER_DB_NAME ADSERVER_DB_USER ADSERVER_DB_PASS]) {
    push @errors, $_ unless defined $ENV{$_};
  }

  if (@errors) {
    die 'Please set the following environment variables: ',
        join(', ', @errors), "\n";
  }

  my $dsn = "dbi:mysql:host=$ENV{ADSERVER_DB_HOST};database=$ENV{ADSERVER_DB_NAME}";
  if ($ENV{ADSERVER_DB_PORT}) {
    $dsn .= ";port=$ENV{ADSERVER_DB_PORT}";
  }

  my $sch = __PACKAGE__->connect(
    $dsn, $ENV{ADSERVER_DB_USER}, $ENV{ADSERVER_DB_PASS},
    { mysql_enable_utf8 => 1, quote_char => '`' },
  );

  # For caching.
  $DBIx::Class::ResultSourceHandle::thaw_schema = $sch;

  return $sch;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
