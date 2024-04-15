package AdServer::Model;

use feature 'signatures';
no warnings 'experimental::signatures';

use AdServer::Schema;

use Moo;
use Types::Standard 'InstanceOf';

has schema => (
  is => 'lazy',
  isa => InstanceOf['AdServer::Schema'],
);

sub _build_schema { return AdServer::Schema->get_schema; }

sub get_client_from_code ($self, $client_code, $get_campaigns = 0) {
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

sub get_client_campaign_from_code ($self, $client, $campaign_code, $get_ads = 0) {
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

sub get_ad_from_code ($self, $campaign, $ad_code) {
  return unless $campaign;
  return $campaign->ads->find({
    code => $ad_code,
  });
}

sub get_ad_from_hash ($self, $ad_hash) {
  return $self->schema->resultset('Ad')->find({ hash => $ad_hash});
}

sub get_clients($self) {
  return map { { $_->get_columns } } $self->schema->resultset('Client')->all;
}

1;