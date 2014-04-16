#!/usr/local/bin/perl 

use strict;
use warnings;
use WWW::YouTube::Download;

#------------------------------------------------------------
#youtubeの動画をぶっこ抜く。
#------------------------------------------------------------

#------------------------------------------------------------
#モジュールの内部メソッドを外部から書き換える。
&_fixup();
sub _fixup{
    return if WWW::YouTube::Download->VERSION != 0.56;
    package WWW::YouTube::Download;
    no warnings 'redefine';

    *_get_args = sub {
        my ($self, $content) = @_;
        my $data;
        for my $line (split "\n", $content) {
            next unless $line;
            if ($line =~ /the uploader has not made this video available in your country/i) {
                croak 'Video not available in your country';
            }
            elsif ($line =~ /^.+ytplayer\.config\s*=\s*({.*})/) {
                my $js = $1;
                $js =~ s/;\(function.*$//;
                $data = JSON->new->utf8(1)->decode($js);
                last;
            }
        }
        croak 'failed to extract JSON data' unless $data->{args};
        return $data->{args};
    };
    *WWW::YouTube::Download::_get_args = \&_get_args;

    *_parse_stream_map = sub {
        my $param       = shift;
        my $fmt_url_map = {};
        for my $stuff (split ',', $param) {
            my $uri = URI->new;
            $uri->query($stuff);
            my $query = +{ $uri->query_form };
            my $url = $query->{url};
            $fmt_url_map->{$query->{itag}} = $url;
        }
        return $fmt_url_map;
    };
    *WWW::YouTube::Download::_parse_stream_map = \&_parse_stream_map;

    return 1;
}
#------------------------------------------------------------


my $video_id = 'LVHyjHd5_CA';

my $client = WWW::YouTube::Download->new;

my $video_url = $client->get_video_url($video_id);
my $title     = $client->get_title($video_id);     # maybe encoded utf8 string.
my $fmt       = $client->get_fmt($video_id);       # maybe highest quality.
my $suffix    = $client->get_suffix($video_id);    # maybe highest quality file suffix

print "url    = $video_url\n";
print "title  = $title\n";
print "fmt    = $fmt\n";
print "suffix = $suffix\n";

$client->download($video_id);
