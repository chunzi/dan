package dan;

use FindBin;
use Dancer ':syntax';
use Text::Markdown qw/ markdown /;
use Path::Class;
use File::Slurp::Unicode;
use Class::Date qw/ date /;

our $VERSION = '0.1';



my $post_dir = dir("$FindBin::Bin/../posts");

get '/' => sub {
    my @post_files = grep { -f and $_->basename =~ /\.md/ } $post_dir->children;
    my @posts = map {
        my $lines = read_file("$_");
        my ( $header, $body ) = split "\n\n", $lines, 2;
        my $meta = {};
        map { 
            my ( $key, $value ) = split /\:/, $_, 2;
            $meta->{$key} = $value;
        } split "\n", $header;
        my $uri = $_->basename;
        $uri =~ s/\.md$/\.html/;

        {
            title => $meta->{'title'},
            slug => $meta->{'slug'},
            date => date($meta->{'date'}),
            uri => $uri,
        }
    } @post_files;

    var posts => \@posts;
    template 'index', vars;
};

get '/post/:name' => sub {
    my $name = params->{'name'};
    $name =~ s/\.html/\.md/g;
    my $file = $post_dir->file( $name );
    my $lines = read_file("$file");
    my ( $header, $body ) = split "\n\n", $lines, 2;
    my $content = markdown( $body );
    var html => $content;
    template 'post', vars;
};

true;
