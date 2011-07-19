package dan::entry;
use strict;
use warnings;

use Class::Date qw/ date /;
use DateTime;
use File::Slurp::Unicode;
use Path::Class;
use Text::Markdown qw/ markdown /;
use YAML::Syck;
use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw/ 
    path 
    day slug format
    created updated 
    body title html
/);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub mtime { file( shift->path )->stat->mtime };

sub parse_from_file {
    my $self = shift;
    my $path = file shift;
    return unless -f $path;

    $self->path( $path->stringify );

    my $basename = lc $path->basename;
    my ( $yy, $mm, $dd, $slug, $format ) = ( $basename =~ /^(\d\d\d\d)-(\d\d)-(\d\d)-?(.*?)\.([a-z]+)$/ );
    my $day = date [ $yy, $mm, $dd, 0, 0, 0 ];
    $format = 'markdown' if $format eq 'md';


    $self->day( $day );
    $self->slug( $slug );
    $self->format( $format );
    $self->created( $day );
    $self->updated( $day );


    # from file content, remove first blank lines
    # extract the YAML Front Matter part if it exists
    my $body = read_file( $self->path );
    $body =~ s/^(\s*\n)+//sm;
    if ( $body =~ /^---/ ){
        ( my $yaml, $body ) = split /\n---\n/, $body, 2;
        $body =~ s/^(\s*\n)+//sm;

        # may support more meta later
        my $meta = Load( $yaml );
        $self->created( date $meta->{'created'} ) if $meta->{'created'};
        $self->updated( date $meta->{'updated'} ) if $meta->{'updated'};
    }
    $self->body( $body );

    # convert taskpaper as markdown text
    if ( $format eq 'taskpaper' ){
        $body =~ s/^\s*//smg;
        $body =~ s/^-\s*$//smg;
        $body =~ s/^(.*?):\s*$/# $1/smg;
    }
    my $html = markdown $body;
    my ( $title ) = ( $html =~ /<h\d>(.*?)<\/h\d>/ );
    
    $self->title( $title );
    $self->html( $html );

    return $self;
}


# for feeds
sub issued   { DateTime->from_epoch( epoch => shift->created->epoch ) }
sub modified { DateTime->from_epoch( epoch => shift->updated->epoch ) }

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

sub uri {
    my $self = shift;
    my $ymd = $self->day->strftime("%Y-%m-%d");
    my $name = join '-', grep { defined and $_ ne '' } $ymd, $self->slug;
    my $link = sprintf "%s.html", $name;
    return $link;
}



1;
