#!/usr/bin/env perl
use strict;
use warnings;
our $VERSION = '0.01';

use Git::Repository;

my $dir = '/Users/chunzi/github/dan-taskpapers';
my $r = Git::Repository->new( work_tree => $dir );


#---------------------------
# which files modified or added
my $status = $r->command( 'status', '--porcelain' ); 
my $log = $status->stdout;
my @files;
while (<$log>) {
    chomp;
    s/^\s+//;
    my ( $code, $name ) = split /\s+/, $_, 2;
    push @files, $name;
}
$status->close;


#---------------------------
if ( @files ){
    # just add them all
    for ( @files ){
        $r->run( 'add' => $_ ); 
        printf STDERR "Added $_\n";
    }


    # and commit, push
    $r->run( 'commit' => '-m', 'auto commit' ); 
    printf STDERR "Commited.\n";
    $r->run( 'push' );
    printf STDERR "Pushed.\n";
}

exit;
