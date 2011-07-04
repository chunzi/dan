package dan;

use FindBin;
use Dancer ':syntax';
use Text::Markdown qw/ markdown /;
use Path::Class;
use File::Slurp::Unicode;
use Class::Date qw/ date /;

our $VERSION = '0.1';



my $post_dir = dir("$FindBin::Bin/../posts");
my @post_files = grep { -f and $_->basename =~ /\.md/ } $post_dir->children;
my @posts = map { file2post( $_ ) } @post_files;

get '/' => sub {
    var posts => \@posts;
    template 'index', vars;
};

get '/post/:name' => sub {
    my $name = params->{'name'};
    $name =~ s/\.html/\.md/g;
    for ( 0 .. $#posts ){
        if ( $name eq $posts[$_]->{'name'} ){
            var post => $posts[$_];
        }
        if ( $_ > 0 ){
            var prev_post => $posts[$_-1];
        }
        if ( $_ < $#posts ){
            var next_post => $posts[$_+1];
        }
    }
    template 'post', vars;
};

sub file2post {
    my $file = shift;
    my $lines = read_file("$file");
    my ( $header, $body ) = split "\n\n", $lines, 2;
    my $meta = {};
    map { 
        my ( $key, $value ) = split /\:/, $_, 2;
        $meta->{$key} = $value;
    } split "\n", $header;
    my $uri = $file->basename;
    $uri =~ s/\.md$/\.html/;

    my $post = {
        name => $file->basename,
        title => $meta->{'title'},
        slug => $meta->{'slug'},
        date => date($meta->{'date'}),
        uri => $uri,
        html => markdown( $body || '' ),
    };
    return $post;
}

true;
