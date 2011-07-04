#!/usr/bin/env perl

use strict;
use warnings;
our $VERSION = '0.01';

use Class::Date qw/ gmdate /;
use Encode;
use Path::Class;
use File::Slurp::Unicode;
use FileHandle;
use FindBin;
use Lingua::Han::PinYin;
use XML::RSS::Parser;
 

# note: this tool is far from perfect
# but it just works, just dump the posts in to posts directory
# with basic markdown syntax. but there still have some small problems
# you need verify and fix them manually.
# this tool is just a dirty-helper script.


# which file to import
my $file = shift;
die "xml file not exists: $file\n" unless -f $file;

XML::RSS::Parser->register_ns_prefix('wp','http://wordpress.org/export/1.1/');
my $fh = FileHandle->new($file);
my $parser = new XML::RSS::Parser;
my $feed = $parser->parse_file($fh);

my $post_dir = dir("$FindBin::Bin/../posts");
my $h2p = Lingua::Han::PinYin->new(format => 'utf8');

my @attachments = ();
for ( $feed->items ){
    my $title = $_->query('title')->text_content;
    my $date  = gmdate( $_->query('wp:post_date_gmt')->text_content );
    my $content  = $_->query('content:encoded')->text_content;

    # should use new image hosting provider
    my $att = $_->query('wp:attachment_url');
    if ( $att ){
        my $url  = $att->text_content;
        push @attachments, $url;


    # the post file
    }else{
        my $slug = title2slug( $title );
        my $filename = filename( $date, $slug );
        my $markdown = html2markdown( $content );

        my $post = sprintf "title: %s\n", $title;
        $post .= sprintf "slug: %s\n", $slug;
        $post .= sprintf "date: %s\n", $date;
        $post .= sprintf "\n# %s\n\n", $title;
        $post .= sprintf "%s\n", $markdown;

        write_file( $post_dir->file($filename)->stringify, $post );
        printf "  %s\n", $filename;
    }
}
write_file( $post_dir->file('00-attachments.md')->stringify, join "\n", @attachments );

sub title2slug {
    my $title = shift;
    my $slug = lc join ('-', $h2p->han2pinyin(  encode( 'utf-8', $title ) ));
    $slug =~ s/-([a-z0-9])\b/$1/g;
    $slug =~ s/\W+/_/g;
    $slug =~ s/^_|_$//g;
    return $slug;
}

sub filename {
    my $date = shift;
    my $slug = shift;
    my $filename = sprintf "%4d-%02d-%02d-%s.md", $date->year, $date->month, $date->day, $slug;
    return $filename;
}

sub html2markdown {
    my $str = shift;
    $str =~ s/<a href="(.*?)">(.*?)<\/a>/\[$2\]\($1\)/smg;
    $str =~ s/<img class="(.*?)" title="(.*?)" src="(.*?)" alt="(.*?)" .*?\/>/\!\[$4\]\($3 "$2"\)/smg;
    $str =~ s/\r//smg;
    $str =~ s/^\* /- /smg;
    $str =~ s/^\s*<\/?[ou]l>/\n\n/smg;
    $str =~ s/^\s*<li>(.*?)<\/li>/- $1/smg;
    $str =~ s/\n<pre lang=".*?">//smg;
    $str =~ s/<\/pre>\n//smg;
    return $str;
}







