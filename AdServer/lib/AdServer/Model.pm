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
    return $self->schema->resultset('Client')->find_live({
      code => $client_code,
    }, {
      prefetch => 'campaigns',
    });
  }

  return $self->schema->resultset('Client')->find_live({
    code => $client_code,
  });
}

sub get_client_campaign_from_code {
  my $self = shift;
  my ($client, $campaign_code, $get_ads) = @_;

  return unless $client;
  if ($get_ads) {
    return $client->campaigns->find_live({
      code => $campaign_code,
    }, {
      prefetch => 'ads',
    });
  }

  return $client->campaigns->find_live({
    code => $campaign_code,
  });
}

sub get_ad_from_code {
  my $self = shift;
  my ($campaign, $ad_code) = @_;

  return unless $campaign;
  return $campaign->ads->find_live({
    code => $ad_code,
  });
}

sub get_ad_from_hash {
  my $self = shift;
  my ($ad_hash) = @_;

  return $self->schema->resultset('Ad')->find_live({ hash => $ad_hash});
}

sub get_clients {
  my $self = shift;

  return map { { $_->get_columns } } $self->schema->resultset('Client')->search_live;
}

sub dashboard_stats {
  my ($self) = @_;
  my $schema = $self->schema;
  my $impressions = $schema->resultset('Impression')->count;
  my $clicks = $schema->resultset('Click')->count;
  # Aggregate each event table separately to avoid multiplying counts when an
  # ad has several impressions and several clicks.
  my $ads = $schema->storage->dbh->selectall_arrayref(q{
    SELECT ad.id, ad.name, client.name AS client_name,
           campaign.name AS campaign_name,
           (COALESCE(ad.is_live, 0) = 1 AND COALESCE(campaign.is_live, 0) = 1
             AND COALESCE(client.is_live, 0) = 1) AS serving,
           COALESCE(i.total, 0) AS impressions, COALESCE(c.total, 0) AS clicks
    FROM ad
    LEFT JOIN campaign ON campaign.id = ad.campaign_id
    LEFT JOIN client ON client.id = campaign.client_id
    LEFT JOIN (SELECT ad_id, COUNT(*) AS total FROM impression GROUP BY ad_id) i
      ON i.ad_id = ad.id
    LEFT JOIN (SELECT ad_id, COUNT(*) AS total FROM click GROUP BY ad_id) c
      ON c.ad_id = ad.id
    ORDER BY client.name, campaign.name, ad.name, ad.id
  }, { Slice => {} });
  for my $ad (@$ads) {
    $ad->{ctr} = $ad->{impressions}
      ? sprintf('%.2f', 100 * $ad->{clicks} / $ad->{impressions}) : '0.00';
  }
  return {
    impressions => $impressions, clicks => $clicks,
    ctr => $impressions ? sprintf('%.2f', 100 * $clicks / $impressions) : '0.00',
    ads => $ads, ad_count => scalar @$ads,
    serving_count => scalar(grep { $_->{serving} } @$ads),
  };
}

1;
