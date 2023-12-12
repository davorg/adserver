use utf8;
package AdServer::Schema::Result::Impression;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdServer::Schema::Result::Impression

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<impression>

=cut

__PACKAGE__->table("impression");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 ad_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 referer

  data_type: 'varchar'
  is_nullable: 1
  size: 2048

=head2 timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: 'current_timestamp()'
  is_nullable: 0

=head2 medium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ip_addr

  data_type: 'char'
  is_nullable: 1
  size: 40

=head2 user_agent

  data_type: 'varchar'
  is_nullable: 1
  size: 2048

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "ad_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "referer",
  { data_type => "varchar", is_nullable => 1, size => 2048 },
  "timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => "current_timestamp()",
    is_nullable => 0,
  },
  "medium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ip_addr",
  { data_type => "char", is_nullable => 1, size => 40 },
  "user_agent",
  { data_type => "varchar", is_nullable => 1, size => 2048 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 ad

Type: belongs_to

Related object: L<AdServer::Schema::Result::Ad>

=cut

__PACKAGE__->belongs_to(
  "ad",
  "AdServer::Schema::Result::Ad",
  { id => "ad_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-12-12 13:13:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fKDqq3LAdOMLsSJHw16JPQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
