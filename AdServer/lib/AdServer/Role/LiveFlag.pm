package AdServer::Role::LiveFlag;

use Moose::Role;

sub search_live {
    my ($self, $search, $attrs) = @_;
    $search //= {};
    $search->{is_live} = 1;
    return $self->search($search, $attrs);
}

sub find_live {
    my ($self, $search, $attrs) = @_;
    $search //= {};
    $search->{is_live} = 1;
    return $self->find($search, $attrs);
}

1;
