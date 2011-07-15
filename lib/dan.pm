package dan;

use FindBin;
use Dancer ':syntax';
use Dancer::Plugin::Feed;
use Path::Class;
use dan::entry;
use dan::channel;

our $VERSION = '0.1';


my $data_dir = dir("$FindBin::Bin/../data");
my $posts = dan::channel->new({ name => 'post', path => './data/posts' });
$posts->sync;
my $en = $posts->entries;

get '/' => sub {
    var posts => [ @$en[0..19] ];
    template 'index', vars;
};

get '/post/:uri' => sub {
    my $uri = params->{'uri'};
    for ( 0 .. $#{$en} ){
        if ( $uri eq $en->[$_]{'uri'} ){
            my $post = dan::entry->new( $en->[$_]{'path'} );
            $post->parse;
            var post => $post;
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
            }} $en->[ 0 .. 6 ]
        ],
    );
};



true;
