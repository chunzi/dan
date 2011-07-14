#!/usr/bin/env perl
use strict;
use warnings;
our $VERSION = '0.01';

use File::Slurp::Unicode;
use Class::Date qw/ date -DateParse /;

our $dir = '/Users/chunzi/github/chunzi.dan/taskpapers'; 

my $today = date( time );
my $filename = sprintf "%s/%s.taskpaper", $dir, $today->strftime( '%Y-%m-%d' );

unless ( -f $filename ){
    my $text = sprintf "%s:\n\n\t- ", $today->strftime( '%b %e, %Y' );
    write_file( $filename, $text );
    printf STDERR "Created %s\n", $filename;
}

system( 'open', $filename );
printf STDERR "Opened %s\n", $filename;

exit;
