package AdServer;
use Dancer2;
use AdServer::Schema;

our $VERSION = '0.1';

get '/' => sub {
  return {
    app => 'AdServer',
  };
};

get '/client/:client_code/campaign/:campaign_code/ad/:ad_code' => sub {

  my $client_code = route_parameters->get('client_code');
  my $campaign_code = route_parameters->get('campaign_code');
  my $ad_code = route_parameters->get('ad_code');
  my $sch = AdServer::Schema->get_schema;

  my $client = $sch->resultset('Client')->find({
    code => $client_code,
  });

  return 404, { error => "Can't find client $client_code" } unless $client;

  my $campaign = $client->campaigns->find({
    code => $campaign_code,
  }, {
    prefetch => 'ads',
  });

  return 404, { error => "Can't find campaign $campaign_code" } unless $campaign;

  my $ad = $campaign->ads->find({
    code => $ad_code,
  });

  return 404, { error => "Can't find ad $ad_code" } unless $ad;

  return { $ad->get_columns };
};

get '/client/:client_code' => sub {
  my $client_code = route_parameters->get('client_code');
  my $sch = AdServer::Schema->get_schema;
  my $client = $sch->resultset('Client')->find({
    code => $client_code,
  }, {
    prefetch => { 'campaigns' => 'ads' },
  });

  return 404, { error => "Can't find client $client_code" } unless $client;

use Data::Printer;

  my @ads = map { $_->ads->all } $client->campaigns;

  my $ad = @ads > 1 ? $ads[rand @ads] : $ads[0];

# warn np $ad;

  return { $ad->get_columns };
};

true;
