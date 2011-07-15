package dan::entry;
use strict;
use warnings;

use Class::Date qw/ date /;
use DateTime;
use File::Slurp::Unicode;
use Path::Class;
use Text::Markdown qw/ markdown /;
use YAML::Syck;
use Digest::SHA1  qw/ sha1_hex /;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ path title slug body created updated day format /);

sub new {
    my $class = shift;
    my $path = shift;
    return unless $path;

    my $self = bless {}, $class;
    $self->path( "$path" );

    return $self;
}

sub shape {
    my $self = shift;
    my $path = file $self->path;
    my $shape = sha1_hex( 
        map { sha1_hex( $_ ) } ( 
            $path->basename, 
            $path->stat->ctime, $path->stat->mtime, 
        ));
    return $shape;
}

sub parse {
    my $self = shift;
    my $path = file $self->path;
    return unless -f $path;

    # from filename
    my $basename = lc $path->basename;
    my ( $year, $month, $day, $slug, $format ) = ( $basename =~ /^(\d\d\d\d)-(\d\d)-(\d\d)-?(.*?)\.([a-z]+)$/ );
    my $ymd = date [ $year, $month, $day, 0, 0, 0 ];
    $format = 'markdown' if $format eq 'md';

    $self->slug( $slug );
    $self->day( $ymd );
    $self->format( $format );

    # from content
    $self->_parse_markdown if $format eq 'markdown';
    $self->_parse_taskpaper if $format eq 'taskpaper';

}

sub _parse_markdown {
    my $self = shift;

    my $body = read_file( $self->path );
    $body =~ s/^(\s*\n)+//sm;

    if ( $body =~ /^---/ ){
        ( my $yaml, $body ) = split /\n---\n/, $body, 2;
        my $meta = Load( $yaml );
        $self->created( date $meta->{'created'} );
        $self->updated( date $meta->{'updated'} );
        $body =~ s/^(\s*\n)+//sm;
    }

    my ( $title ) = split /\n/, $body;
    $title =~ s/^#*\s*//;
    $title =~ s/\s+$//;

    $self->title( $title );
    $self->body( $body );
}

sub content {
    my $self = shift;
    return markdown $self->body;
}

sub content_without_title {
    my $self = shift;
    my $content = $self->content;
    $content =~ s{<h\d>.*?</h\d>\n\n}{}s;
    return $content;
}

sub touch {
    my $self = shift;
#    $self->updated( date time );
    my $yaml = $self->yaml_header;
    my $text = sprintf "%s---\n\n%s", $yaml, $self->rawbody;
    write_file( $self->path, $text );
}

sub yaml_header {
    my $self = shift;
    my $meta = {};
    $meta->{'created'} = $self->created->string;
    $meta->{'updated'} = $self->updated->string;
    my $yaml = Dump( $meta );
    return $yaml;
}

sub _parse_taskpaper {
    my $self = shift;
    my $lines = read_file( $self->path );
}

sub ctime {
    my $self = shift;
    my $path = file $self->path;
    return date $path->stat->ctime;
}

sub mtime {
    my $self = shift;
    my $path = file $self->path;
    return date $path->stat->mtime;
}

sub uri {
    my $self = shift;
    my $ymd = $self->day->strftime("%Y-%m-%d");
    my $link = sprintf "%s-%s.html", $ymd, $self->slug; 
    return $link;
}

sub issued {
    my $self = shift;
    my $date = DateTime->from_epoch( epoch => $self->created->epoch );
    return $date;
}

sub modified {
    my $self = shift;
    my $date = DateTime->from_epoch( epoch => $self->updated->epoch );
    return $date;
}

1;
