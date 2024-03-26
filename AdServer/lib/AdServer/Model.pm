use Feature::Compat::Class;

class AdServer::Model;

use AdServer::Schema;

field $schema = AdServer::Schema->get_schema;

method schema { return $schema; }

method get_client_from_code ($client_code, $get_campaigns) {
  if ($get_campaigns) {
    return $schema->resultset('Client')->find({
      code => $client_code,
    }, {
      prefetch => 'campaigns',
    });
  }

  return $schema->resultset('Client')->find({
    code => $client_code,
  });
}

method get_client_campaign_from_code ($client, $campaign_code, $get_ads) {
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

method get_ad_from_code ($campaign, $ad_code) {
  return unless $campaign;
  return $campaign->ads->find({
    code => $ad_code,
  });
}

method get_ad_from_hash ($ad_hash) {
  return $schema->resultset('Ad')->find({ hash => $ad_hash});
}

1;