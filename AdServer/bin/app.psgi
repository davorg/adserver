#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

=begin comment
# use this block if you don't need middleware, and only have a single target Dancer app to run here

use AdServer;

AdServer->to_app;

=end comment

=cut

# use this block if you want to include middleware such as Plack::Middleware::Deflater

use AdServer;
use Plack::Builder;


builder {
  enable 'Static',
    path => qr[^/(images|css|javascripts)/], root => './AdServer/public', pass_through => 1;
  AdServer->to_app;
};

=begin comment
# use this block if you want to mount several applications on different path

use AdServer;
use AdServer_admin;

use Plack::Builder;

builder {
    mount '/'      => AdServer->to_app;
    mount '/admin'      => AdServer_admin->to_app;
}

=end comment

=cut

