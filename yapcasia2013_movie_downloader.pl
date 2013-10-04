#!C:\strawberry\perl\bin\perl.exe

#--------------------------------------------------------------------------------------------------
#YAPC::Asia 2013の1日目、2日目の動画をダウンロードするスクリプト
#--------------------------------------------------------------------------------------------------
use strict;
use warnings;
use Data::Dumper;
use utf8;
use URI;
use Encode;
#--------------------------------------------------------------------------------------------------
use Web::Scraper;
use WWW::YouTube::Download;
#--------------------------------------------------------------------------------------------------


&downloader('2013-09-20');
&downloader('2013-09-21');


sub downloader{
	my $dt = shift;
	my $uri = URI->new("http://yapcasia.org/2013/talk/schedule?date=" . $dt);
	my $scraper = scraper {
	    process 'div[class="title"] > a[href]', 'urls[]' => '@href';
	};
	my $scraper2 = scraper {
		process 'div[class="video"] > iframe[src]', 'url' => '@src';
	};
	my $client = WWW::YouTube::Download->new;

	my $result = $scraper->scrape($uri);

	for my $data (@{$result->{urls}}) {
		my $uri2 = URI->new($data);

		my $result2 = $scraper2->scrape($uri2);

		#youtubeのURLが取れなかったら次へ。
		if (!defined($result2->{url})) {
			next;
		}

		my $video_id = $result2->{url};
		$video_id =~ s/^.+embed\/(.+)\?.*/$1/;

		#youtubeのidが取れなかったら次へ。
		if ($video_id eq '') {
			next;
		}

		#タイトルの取得。
		my $title = $client->get_title($video_id);
		$title =~ s/[\?\/\>\<\/\:\;\~\{\}\'\"\[\]\*\|]//ig;			#"'widnowsでファイル名に使えない文字を消去
		$title = Encode::encode('cp932', decode_utf8($title));
		$title =~ s/[\?]//g;																		#utf8からsjisに変換できなかった文字を削除。

		print $video_id . "\n->" . $title . "\n";

		#mp4がすでにある場合は次へ。
		if (-f $dt . '_' . $title . '.mp4') {
			print "->skip!\n";
			next;
		}else{
			print "->download...\n";
		}

		#ダウンローーーード。
		$client->download($video_id, {
			filename => $dt . '_' . $title . '.mp4',
			fmt      => 18
		});
		print "->ok!\n";
	}
}
