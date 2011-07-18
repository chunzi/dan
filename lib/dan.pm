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
my $posts = dan::channel->new({ name => 'post', path => './data/posts' });

use Benchmark;
my $t0 = Benchmark->new;
$posts->sync;
my $en = $posts->entries;
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);
print STDERR "the code took:",timestr($td),"\n";
print STDERR Dumper $posts->load_index_db;

get '/' => sub {
    my $en = $posts->entries;
    var posts => [ @$en[0..19] ];
    template 'index', vars;
};

get '/post/:uri' => sub {
    my $en = $posts->entries;
    my $uri = params->{'uri'};
    for ( 0 .. $#{$en} ){
        if ( $uri eq $en->[$_]->{'uri'} ){
            var post => dan::entry->new($en->[$_]->{'path'})->parse;
            last;
        }
    }
    template 'post', vars;
};

get '/feed' => sub {
    $posts->sync;
    my $en = $posts->entries;
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
