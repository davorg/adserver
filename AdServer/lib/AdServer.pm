package AdServer;
use Dancer2;
use FindBin '$RealBin';

use Sys::Hostname;

use AdServer::Model;

our $VERSION = '0.4.0';

my $model = AdServer::Model->new;
my $sch = $model->schema;

get '/dashboard' => sub {
  response_header 'Cache-Control' => 'no-store';
  return template 'dashboard', { stats => $model->dashboard_stats, version => $VERSION },
    { layout => undef };
};

get '/dashboard/graph' => sub {
  content_type 'application/json';
  response_header 'Cache-Control' => 'no-store';
  my %args = map { $_ => query_parameters->get($_) } qw(metric scope from to);
  my $graph = eval { $model->dashboard_graph(%args) };
  unless ($graph) {
    status 400;
    return encode_json({ error => 'Choose a valid filter, metric, and date range of 1 to 366 days.' });
  }
  return encode_json($graph);
};

get '/' => sub {
  content_type 'application/json';
  return encode_json({
    app  => 'AdServer',
    ver  => $VERSION,
    host => hostname,
  });
};

get '/client/:client_code/campaign/:campaign_code/ad/:ad_code' => sub {

  my $client_code = route_parameters->get('client_code');
  my $campaign_code = route_parameters->get('campaign_code');
  my $ad_code = route_parameters->get('ad_code');

  my $client = $model->get_client_from_code($client_code);

  send_error("Can't find client $client_code", 404) unless $client;

  my $campaign = $model->get_client_campaign_from_code($client, $campaign_code, 1);

  send_error("Can't find campaign $campaign_code for $client_code", 404) unless $campaign;

  my $ad = $model->get_ad_from_code($campaign, $ad_code);

  send_error("Can't find ad $ad_code in campaign $campaign_code for client $client_code", 404) unless $ad;

  return template @{ $ad->serve(request) };
};

get '/client/:client_code/campaign/:campaign_code' => sub {

  my $client_code = route_parameters->get('client_code');
  my $campaign_code = route_parameters->get('campaign_code');

  my $client = $model->get_client_from_code($client_code);

  send_error("Can't find client $client_code", 404) unless $client;

  my $campaign = $model->get_client_campaign_from_code($client, $campaign_code, 1);

  send_error("Can't find campaign $campaign_code for $client_code", 404) unless $campaign;

  my @ads = $campaign->ads->search_live;

  send_error("Can't find any ads in campaign $campaign_code for client $client_code", 404)
    unless @ads;

  my $ad = @ads > 1 ? $ads[rand @ads] : $ads[0];

  return template @{ $ad->serve(request) };
};

get '/client/:client_code' => sub {
  my $client_code = route_parameters->get('client_code');
  my $client = $model->get_client_from_code($client_code, 1);

  send_error("Can't find client $client_code", 404) unless $client;

  my @ads = map { $_->ads->search_live } $client->campaigns->search_live;

  send_error("Can't find any ads for client $client_code", 404)
    unless @ads;

  my $ad = @ads > 1 ? $ads[rand @ads] : $ads[0];

  return template @{ $ad->serve(request) };
};

get '/client' => sub {
  content_type 'application/json';

  return encode_json({
    clients => [ $model->get_clients ],
  });
};

get '/ad/:hash' => sub {
  my $ad_hash = route_parameters->get('hash');
  my $referer = query_parameters->get('referer');
  my $ad = $model->get_ad_from_hash($ad_hash);

  unless ($ad) {
    send_error("Can't find ad $ad_hash", 404);
  }

  send_error('Invalid ad destination', 422) unless $ad->has_valid_destination;

  my $token = query_parameters->get('impression');
  my $impression;
  if (defined $token && $token =~ /\A[0-9a-f]{32}\z/) {
    # Another ad's impression must not supply attribution for this click.
    $impression = $ad->impressions->find({ token => $token });
  }

  $ad->add_to_clicks({
    impression_id => $impression ? $impression->id : undef,
    referer => $impression ? $impression->referer
             : defined $token ? undef : $referer,
  });

  return redirect $ad->url;
};

true;
