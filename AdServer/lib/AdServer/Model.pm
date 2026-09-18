package AdServer::Model;

use AdServer::Schema;
use Time::Piece;
use Time::Seconds qw(ONE_DAY);

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

sub dashboard_graph {
  my ($self, %args) = @_;
  my $dbh = $self->schema->storage->dbh;
  my $today = $dbh->selectrow_array('SELECT CURRENT_DATE');
  my $end = $args{to} || $today;
  my $start = $args{from} || (Time::Piece->strptime($today, '%Y-%m-%d') - 29 * ONE_DAY)->ymd;
  my @dates;
  for ($start, $end) {
    die "Use dates in YYYY-MM-DD format\n" unless /\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/;
    my $date = eval { Time::Piece->strptime($_, '%Y-%m-%d') };
    die "Invalid date\n" unless $date && $date->ymd eq $_;
    push @dates, $date;
  }
  my $days = int(($dates[1] - $dates[0]) / ONE_DAY) + 1;
  die "Choose a date range of 1 to 366 days\n" unless $days > 0 && $days <= 366;
  my $metric = $args{metric} || 'impressions';
  die "Unknown metric\n" unless $metric eq 'impressions' || $metric eq 'clicks';
  my @options = ({ value => 'all', label => 'All ads' });
  for my $client ($self->schema->resultset('Client')->search({}, {order_by => 'name'})) {
    push @options, {kind => 'client', value => 'client:' . $client->id, label => 'Client: ' . $client->name};
  }
  for my $campaign ($self->schema->resultset('Campaign')->search({}, {prefetch => 'client', order_by => 'me.name'})) {
    push @options, {kind => 'campaign', value => 'campaign:' . $campaign->id,
      client => $campaign->client_id ? 'client:' . $campaign->client_id : 'all',
      label => 'Campaign: ' . ($campaign->client ? $campaign->client->name : '(no client)') . ' / ' . $campaign->name};
  }
  for my $ad ($self->schema->resultset('Ad')->search({}, {prefetch => {campaign => 'client'}, order_by => 'me.name'})) {
    my $campaign = $ad->campaign;
    push @options, {kind => 'ad', value => 'ad:' . $ad->id,
      campaign => $campaign ? 'campaign:' . $campaign->id : 'all',
      client => $campaign && $campaign->client_id ? 'client:' . $campaign->client_id : 'all',
      label => 'Ad: ' . ($campaign && $campaign->client ? $campaign->client->name : '(no client)')
        . ' / ' . ($campaign ? $campaign->name : '(no campaign)') . ' / ' . $ad->name};
  }
  my $scope = $args{scope} || 'all';
  my ($selected) = grep { $_->{value} eq $scope } @options;
  die "Unknown ad filter\n" unless $selected;
  my ($where, @bind) = ('');
  if ($scope ne 'all') {
    my ($kind, $id) = split /:/, $scope;
    my %column = (client => 'campaign.client_id', campaign => 'ad.campaign_id', ad => 'ad.id');
    $where = ' AND ' . $column{$kind} . ' = ?';
    push @bind, $id;
  }
  my $table = $metric eq 'clicks' ? 'click' : 'impression';
  my $rows = $dbh->selectall_arrayref(
    "SELECT DATE(event.timestamp) AS day, COUNT(*) AS total FROM $table event " .
    'LEFT JOIN ad ON ad.id = event.ad_id LEFT JOIN campaign ON campaign.id = ad.campaign_id ' .
    'WHERE event.timestamp >= ? AND event.timestamp < ?' . $where .
    ' GROUP BY DATE(event.timestamp) ORDER BY day', {Slice => {}},
    $start, ($dates[1] + ONE_DAY)->ymd, @bind);
  my %counts = map { $_->{day} => $_->{total} } @$rows;
  my @points;
  my $total = 0;
  for my $offset (0 .. $days - 1) {
    my $day = ($dates[0] + $offset * ONE_DAY)->ymd;
    my $count = $counts{$day} || 0;
    $total += $count;
    push @points, {day => $day, count => $count};
  }
  return { from => $start, to => $end, metric => $metric, scope => $scope,
    options => \@options, label => $selected->{label}, points => \@points,
    total => $total };
}

1;
