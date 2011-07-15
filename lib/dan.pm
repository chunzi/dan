package dan;

use FindBin;
use Dancer ':syntax';
use Dancer::Plugin::Feed;
use Text::Markdown qw/ markdown /;
use Path::Class;
use File::Slurp::Unicode;
use Class::Date qw/ date /;
use Data::Dumper;
use dan::entry;

our $VERSION = '0.1';


my $post_dir = dir("$FindBin::Bin/../posts");
my @post_files = grep { -f and $_->basename =~ /\.md/ } $post_dir->children;
my @posts = reverse map { dan::entry->new( $_ ) } @post_files;

get '/' => sub {
    var posts => [ @posts[0..19] ];
    template 'index', vars;
};

get '/post/:uri' => sub {
    my $uri = params->{'uri'};
    for ( 0 .. $#posts ){
        if ( $uri eq $posts[$_]->uri ){
            var post => $posts[$_];
            if ( $_ > 0 ){
                var prev_post => $posts[$_-1];
            }
            if ( $_ < $#posts ){
                var next_post => $posts[$_+1];
            }
            last;
        }
    }
    template 'post', vars;
};

get '/feed' => sub {
    create_rss_feed(
        entries => [ map {{
                title    => $_->title,
                content  => $_->content_without_title,
                issued   => $_->issued,
                modified => $_->modified,
                link     => $_->uri,
            }} @posts[ 0 .. 6 ]
        ],
    );
};



true;
