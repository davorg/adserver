package AdServer;
use Dancer2;
use FindBin '$RealBin';

use AdServer::Model;

our $VERSION = '0.1';

my $model = AdServer::Model->new;
my $sch = $model->schema;

get '/' => sub {
  return {
    app => 'AdServer',
  };
};

get '/client/:client_code/campaign/:campaign_code/ad/:ad_code' => sub {

  my $client_code = route_parameters->get('client_code');
  my $campaign_code = route_parameters->get('campaign_code');
  my $ad_code = route_parameters->get('ad_code');

  my $client = $model->get_client_from_code($client_code);

  return 404, { error => "Can't find client $client_code" } unless $client;

  my $campaign = $model->get_client_campaign_from_code($client, $campaign_code, 1);

  return 404, { error => "Can't find campaign $campaign_code" } unless $campaign;

  my $ad = $model->get_ad_from_code($campaign, $ad_code);

  return 404, { error => "Can't find ad $ad_code" } unless $ad;

  $ad->add_to_impressions({
    ip_addr    => request->remote_address,
    user_agent => request->user_agent,
    referer    => request->referer,
  });

  return template 'standard', {
    request => request,
    ad => $ad,
  }, { layout => undef,
  };
};

get '/client/:client_code/campaign/:campaign_code' => sub {

  my $client_code = route_parameters->get('client_code');
  my $campaign_code = route_parameters->get('campaign_code');

  my $client = $model->get_client_from_code($client_code);

  return 404, { error => "Can't find client $client_code" } unless $client;

  my $campaign = $model->get_client_campaign_from_code($client, $campaign_code, 1);

  return 404, { error => "Can't find campaign $campaign_code" } unless $campaign;

  my @ads = $campaign->ads->all;

  my $ad = @ads > 1 ? $ads[rand @ads] : $ads[0];

  $ad->add_to_impressions({
    ip_addr    => request->remote_address,
    user_agent => request->user_agent,
    referer    => request->referer,
  });

  return template 'standard', {
    request => request,
    ad => $ad,
  }, { layout => undef,
  };
};

get '/client/:client_code' => sub {
  my $client_code = route_parameters->get('client_code');
  my $client = $model->get_client_from_code($client_code, 1);

  return 404, { error => "Can't find client $client_code" } unless $client;

  my @ads = map { $_->ads->all } $client->campaigns;

  my $ad = @ads > 1 ? $ads[rand @ads] : $ads[0];

  $ad->add_to_impressions({
    ip_addr    => request->remote_address,
    user_agent => request->user_agent,
    referer    => request->referer,
  });

  return template 'standard', {
    request => request,
    ad => $ad,
  }, {
    layout => undef,
  };
};

get '/client' => sub {
  my @clients = map {
    {
      code => $_->code,
      name => $_->name,
    }
  } $sch->resultset('Client')->all;

  return {
    clients => \@clients,
  };

};

get '/ad/:hash' => sub {
  my $ad_hash = route_parameters->get('hash');
  my $ad = $model->get_ad_from_hash($ad_hash);

  unless ($ad) {
    status 404 and return "Can't find ad $ad_hash";
  }

  # warn np $ad->get_columns;

  $ad->add_to_clicks({
    referer => request->referer,
  });

  return redirect $ad->url;
};

true;
