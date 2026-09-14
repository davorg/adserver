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
    # find() may discard non-key conditions when resolving a unique key.
    # Scope the result set first so the live flag remains a SQL condition.
    return $self->search({ $self->current_source_alias . '.is_live' => 1 })
        ->find($search, $attrs);
}

1;
