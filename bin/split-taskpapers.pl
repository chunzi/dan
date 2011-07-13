#!/usr/bin/env perl
use strict;
use Data::Dumper;
use File::Slurp::Unicode;
use Class::Date qw/ date  -DateParse /;

my @projects;
my @para;
while(<>){
    chomp;
    s/^\s+|\s+$//g;
    if ( s/:$// ){
        my ( $name ) = map { $_->{'text'} || 'Untitled' } grep { $_->{'class'} eq 'project' } @para;
        if ( $name ){
            push @projects, { name => $name, para => [ @para ] };
            @para = ();
        }
        push @para, { class => 'project', text => $_ };
    }elsif ( s/^-\s+// ){
        push @para, { class => 'task', text => $_ };
    }else{
        push @para, { class => 'note', text => $_ };
    }
}


local $Class::Date::DATE_FORMAT="%b %e, %Y";
for ( @projects ){
    my $filename = sprintf "%s.taskpaper", $_->{'name'};
    my $text;
    for ( @{$_->{'para'}} ){
        my $str = $_->{'text'};
        if ( $_->{'class'} eq 'project' ){
            #if ( $str =~ /^20\d\d-\d\d-\d\d$/ ){
                my $date = date $str;
                $str = "$date"; 
                #}
            $text .= sprintf "%s:\n\n", $str;

        }elsif ( $_->{'class'} eq 'task' ){
            next if $str eq '';
            $text .= sprintf "\t- %s\n", $str;

        }elsif ( $_->{'class'} eq 'note' ){
            next if $str eq '-';
            $text .= sprintf "\t%s\n", $str;
        }
    }
    write_file( $filename, $text );
}

