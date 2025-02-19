package AdServer::Schema::ResultSet::Client;

use Moose;
use MooseX::NonMoose;
extends 'DBIx::Class::ResultSet';

with 'AdServer::Role::LiveFlag';

__PACKAGE__->meta->make_immutable;

1;
