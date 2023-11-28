use utf8;
package AdServer::Schema::Result::Ad;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AdServer::Schema::Result::Ad

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

=head1 TABLE: C<ad>

=cut

__PACKAGE__->table("ad");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 2048

=head2 heading

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 body_text

  data_type: 'text'
  is_nullable: 0

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 hash

  data_type: 'char'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "url",
  { data_type => "varchar", is_nullable => 0, size => 2048 },
  "heading",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "body_text",
  { data_type => "text", is_nullable => 0 },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "hash",
  { data_type => "char", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<hash>

=over 4

=item * L</hash>

=back

=cut

__PACKAGE__->add_unique_constraint("hash", ["hash"]);

=head1 RELATIONS

=head2 campaign

Type: belongs_to

Related object: L<AdServer::Schema::Result::Campaign>

=cut

__PACKAGE__->belongs_to(
  "campaign",
  "AdServer::Schema::Result::Campaign",
  { id => "campaign_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "RESTRICT",
  },
);

=head2 clicks

Type: has_many

Related object: L<AdServer::Schema::Result::Click>

=cut

__PACKAGE__->has_many(
  "clicks",
  "AdServer::Schema::Result::Click",
  { "foreign.ad_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-11-28 12:13:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qrqwrgTcAVcA7DeqMjE4YQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
