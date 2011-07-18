package dan::channel;
use strict;
use warnings;

use Class::Date qw/ date /;
use Path::Class;
use dan::entry;
use Data::Page;
use Digest::SHA1  qw/ sha1_hex /;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ path name dbfile db /);

sub new {
    my $class = shift;
    my $path = shift;
    return unless -d $path;

    my $self = bless {}, $class;

    $self->path( $path );
    $self->db( { mtime => 0, files => {} } );
    $self->sync;

    return $self;
}


sub sync {
    my $self = shift;
    my $db = $self->db;

    my $mtime = (stat( $self->path ))[9];
    return if ( exists $db->{'mtime'} and $db->{'mtime'} == $mtime );

    $db->{'mtime'} = $mtime;
    my $index = $db->{'files'};

    my @path = 
        map { $_->stringify } map { $_->absolute }
        grep { $_->basename !~ /\.db$/ } grep { -f } 
        dir( $self->path )->children( no_hidden => 1 );


    my $remove = {};
    map { $remove->{$_}++ } keys %{$db->{'files'}};
    for my $path ( @path ){
        my $mtime = (stat $path)[9];
        my $sha = sha1_hex( $path, $mtime );

        if ( not exists $index->{$sha} ){
            my $entry = dan::entry->new( $path );
            $entry->parse;
            $index->{$sha} = $entry;

        }else{
            delete $remove->{$sha};
        }
    }
    map { delete $index->{$_} } keys %$remove;

}

sub page {
    my $self = shift;
    my $cur_page = shift || 1;
    my $per_page = shift || 1;

    my @entries = $self->entries;
    my $total = scalar @entries;

    my $page = Data::Page->new();
    $page->total_entries( $total );
    $page->entries_per_page( $per_page );
    $page->current_page( $cur_page );
    my @show = $page->splice( \@entries );

    return @show;
}

sub find {
    my $self = shift;
    my $uri = shift;

    my @all = $self->entries;
    my $found;
    for ( 0 .. $#all ){
        if ( $uri eq $all[$_]->uri ){
            $found = $_;
            last;
        }
    }

    return $all[$found], $all[$found-1], $all[$found+1];
}

sub entries {
    my $self = shift;
    $self->sync;
    my @sorted = 
        map { $_->[1] } sort { $b->[0] <=> $a->[0] }
        map { [ $_->created->epoch, $_ ] }
        values %{$self->db->{'files'}};
    return @sorted;
}


1;
