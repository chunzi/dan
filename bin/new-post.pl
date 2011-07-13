#!/usr/bin/env perl
use strict;
use warnings;
our $VERSION = '0.01';

use File::Slurp::Unicode;
use Class::Date qw/ date -DateParse /;

our $dir = '/Users/chunzi/github/chunzi.dan/posts'; 

my $today = date( time );
my $filename = sprintf "%s/%s-slug.md", $dir, $today->strftime( '%Y-%m-%d' );

unless ( -f $filename ){
    my $text = sprintf "title:untitled\nslug:slug\ndate:%s\n\n# ", $today;
    write_file( $filename, $text );
    printf STDERR "Created %s\n", $filename;
}

system( 'open', $filename );
printf STDERR "Opened %s\n", $filename;

exit;
