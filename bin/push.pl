#!/usr/bin/env perl
use strict;
use warnings;
our $VERSION = '0.01';

use Git::Repository;

my $dir = '/Users/chunzi/github/chunzi.dan';
my $r = Git::Repository->new( work_tree => $dir );


#---------------------------
# which files modified or added
my $status = $r->command( 'status', '--porcelain' ); 
my $log = $status->stdout;


my @files_add;
my @files_del;
while (<$log>) {
    chomp;
    s/^\s+//;
    my ( $code, $name ) = split /\s+/, $_, 2;
    push @files_add, $name if $code =~ /[?M]/;
    push @files_del, $name if $code =~ /D/;
}
$status->close;


#---------------------------
if ( @files_add or @files_del ){

    # just add them all
    for ( @files_add ){
        $r->run( 'add' => $_ ); 
        printf STDERR "Added $_\n";
    }
    for ( @files_del ){
        $r->run( 'rm' => $_ ); 
        printf STDERR "Removed $_\n";
    }


    # and commit, push
    $r->run( 'commit' => '-m', 'auto commit' ); 
    printf STDERR "Commited.\n";
    $r->run( 'push' );
    printf STDERR "Pushed.\n";
}

exit;
