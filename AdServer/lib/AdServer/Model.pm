package AdServer::Model;

use AdServer::Schema;

use Moo;
use Types::Standard 'InstanceOf';

has schema => (
  is => 'lazy',
  isa => InstanceOf['AdServer::Schema'],
);

sub _build_schema { return AdServer::Schema->get_schema; }

sub get_client_from_code {
  my $self = shift;
  my ($client_code, $get_campaigns) = @_;

  if ($get_campaigns) {
    return $self->schema->resultset('Client')->find({
      code => $client_code,
    }, {
      prefetch => 'campaigns',
    });
  }

  return $self->schema->resultset('Client')->find({
    code => $client_code,
  });
}

sub get_client_campaign_from_code {
  my $self = shift;
  my ($client_code, $campaign_code, $get_ads) = @_;

  return unless $client;
  if ($get_ads) {
    return $client->campaigns->find({
      code => $campaign_code,
    }, {
      prefetch => 'ads',
    });
  }

  return $client->campaigns->find({
    code => $campaign_code,
  });
}

sub get_ad_from_code {
  my $self = shift;
  my ($campaign, $ad_code) = @_;

  return unless $campaign;
  return $campaign->ads->find({
    code => $ad_code,
  });
}

sub get_ad_from_hash {
  my $self = shift;
  my ($ad_hash) = @_;

  return $self->schema->resultset('Ad')->find({ hash => $ad_hash});
}

sub get_clients {
  my $self = shift;

  return map { { $_->get_columns } } $self->schema->resultset('Client')->all;
}

1;