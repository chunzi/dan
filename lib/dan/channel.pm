package dan::channel;
use strict;
use warnings;

use Class::Date qw/ date /;
use Path::Class;
use dan::entry;
use Storable;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ path name /);


sub dbfile {
    my $self = shift;
    my $dbfile = file( $self->path, 'index.db' )->stringify;
    return $dbfile;
}

sub sync {
    my $self = shift;

    # bless all the files as entry object
    my @entries = 
        map { dan::entry->new($_) }
        grep { $_->basename !~ /\.db$/ } 
        grep { $_->basename !~ /^\./ } 
        grep { -f } dir( $self->path )->children;

    # load previous index, prepare a list to remove old caches
    my $index = $self->load_index_db;
    my $remove = {}; map { $remove->{$_}++ } keys %$index;

    for my $entry ( @entries ){
        my $path = $entry->path;
        my $mtime = $entry->mtime;

        # skip the same ones
        if ( exists $index->{$path} and $index->{$path}{'mtime'} == $mtime ){
            delete $remove->{$path};
            next;
        }

        # attach updated or newly added
        $entry->parse;
        $index->{$path} = {
            mtime   => $mtime,
            path    => $path,
            uri     => $entry->uri,
            title   => $entry->title,
            created => $entry->created,
            epoch   => $entry->created->epoch,
        };
    }

    # remove the missing ones
    map { delete $index->{$_} } keys %$remove;

    my $dbfile = $self->dbfile;
    store $index, $dbfile;
}

sub load_index_db {
    my $self = shift;
    my $dbfile = $self->dbfile;
    my $index = -f $dbfile ? retrieve $dbfile : {};
    return $index;
}

sub entries {
    my $self = shift;
    my $index = $self->load_index_db;
    my @entries = sort { $b->{'epoch'} <=> $a->{'epoch'} } values %$index;
    return \@entries;
}


1;
