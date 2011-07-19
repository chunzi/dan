package dan;

use FindBin;
use Dancer ':syntax';
use Dancer::Plugin::Feed;
use Path::Class;
use dan::entry;
use dan::channel;
use Data::Dumper;

our $VERSION = '0.1';


my $data_dir = dir("$FindBin::Bin/../data");
my $posts = dan::channel->new('./data/posts');
my $taskpapers = dan::channel->new('./data/taskpapers');

get '/' => sub {
    forward '/posts';
};

get '/posts' => sub {
    my @posts = $posts->page( 1, 20 );
    var posts => \@posts;
    template 'posts', vars;
};

get '/post/:uri' => sub {
    my $uri = params->{'uri'};
    my ( $post, $prev, $next ) = $posts->find( $uri );
    var post => $post;
    var prev_post => $prev;
    var next_post => $next;
    template 'post', vars;
};

get '/feed' => sub {
    my @posts = $posts->page( 1, 10 );
    create_rss_feed(
        entries => [ map {{
                title    => $_->title,
                content  => $_->content_without_title,
                issued   => $_->issued,
                modified => $_->modified,
                link     => $_->uri,
            }} @posts
        ],
    );
};

#----------------------------
# taskpapers


get '/taskpapers' => sub {
    my @taskpapers = $taskpapers->page( 1, 20 );
    var taskpapers => \@taskpapers;
    template 'taskpapers', vars;
};

get '/taskpaper/:uri' => sub {
    my $uri = params->{'uri'};
    my ( $taskpaper, $prev, $next ) = $taskpapers->find( $uri );
    var taskpaper => $taskpaper;
    var prev_taskpaper => $prev;
    var next_taskpaper => $next;
    template 'taskpaper', vars;
};


true;
