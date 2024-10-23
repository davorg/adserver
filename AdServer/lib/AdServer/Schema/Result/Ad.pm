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

=head2 image

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 heading

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 body_text

  data_type: 'text'
  is_nullable: 0

=head2 hash

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 campaign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

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
  "image",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "heading",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "body_text",
  { data_type => "text", is_nullable => 0 },
  "hash",
  { data_type => "char", is_nullable => 0, size => 32 },
  "campaign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<campaign_id>

=over 4

=item * L</campaign_id>

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint("campaign_id", ["campaign_id", "code"]);

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

=head2 impressions

Type: has_many

Related object: L<AdServer::Schema::Result::Impression>

=cut

__PACKAGE__->has_many(
  "impressions",
  "AdServer::Schema::Result::Impression",
  { "foreign.ad_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2023-12-04 17:08:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UZcE06gPoa6nRAGObD/7VQ

use Data::Printer;
use Digest::MD5 'md5_hex';

around insert => sub {
  warn np @_;

  my $orig = shift;
  my $self = shift;

  unless ($self->hash) {
    my $sch = $self->result_source->schema;
    my $campaign = $sch->resultset('Campaign')->find($self->campaign_id);
    my $client = $campaign->client;

    my $string = $client->code . ':' . $campaign->code . ':' . $self->code;
    $self->hash(md5_hex($string));
  }

  $self->$orig(@_);
};

sub display_url {
  my $self = shift;

  my $display_url = $self->url;

  # Remove https://
  $display_url =~ s|^https?://||;
  # Remove trailing fragment
  $display_url =~ s|#[-\w]+$||;
  # Remove trailing slash
  $display_url =~ s|/$||;

  return $display_url;
}

sub serve {
  my $self = shift;
  my ($request) = @_;

  $self->add_to_impressions({
    ip_addr    => ($request->remote_address // 'Unknown address'),
    user_agent => ($request->user_agent // 'Unknown UA'),
    referer    => ($request->referer // 'Unknown referer'),
  });

  return [
    'standard',
    {
      request => $request,
      ad      => $self,
      referer => ($request->referer // 'Unknown referer'),
    },
    {
      layout => undef
    },
  ]
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
