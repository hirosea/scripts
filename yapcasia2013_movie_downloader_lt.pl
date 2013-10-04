#!C:\strawberry\perl\bin\perl.exe

#--------------------------------------------------------------------------------------------------
#YAPC::Asia 2013のLTの動画をダウンロードするスクリプト
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


my @urls = qw{
http://www.youtube.com/watch?v=CWc9nmJVh3A
http://www.youtube.com/watch?v=IjXBJ-3af2M
http://www.youtube.com/watch?v=MBC1azF39Ck
http://www.youtube.com/watch?v=M_5c7eM28-E
http://www.youtube.com/watch?v=56jADoxUfls
http://www.youtube.com/watch?v=4JRH1Q7O_zk
http://www.youtube.com/watch?v=IAoJzxBzOok
http://www.youtube.com/watch?v=BZFI2-dlMqw
http://www.youtube.com/watch?v=88z2l9mlPyI
http://www.youtube.com/watch?v=WVqMK8GNcBg
http://www.youtube.com/watch?v=fwjCVdd6-Rg
http://www.youtube.com/watch?v=f2dd1twKIjI
http://www.youtube.com/watch?v=GX1CoCRnvss
http://www.youtube.com/watch?v=ehYpqw8p5qw
http://www.youtube.com/watch?v=eX8FdnTDSA0
http://www.youtube.com/watch?v=4lCyLZ-st-I
http://www.youtube.com/watch?v=ev3HmigTb3k
http://www.youtube.com/watch?v=0TZtYTiorJk
http://www.youtube.com/watch?v=LRPz-Bjjh_g
http://www.youtube.com/watch?v=yiWSR6WAxnc
http://www.youtube.com/watch?v=-XoN5I7_ROs
http://www.youtube.com/watch?v=DuzQFqth_DY
http://www.youtube.com/watch?v=3mc9Kx2nxOg
http://www.youtube.com/watch?v=aUyy8e8MXRE
http://www.youtube.com/watch?v=WCPFFomaT0U
http://www.youtube.com/watch?v=nR0qqZrKhNc
http://www.youtube.com/watch?v=uynfQL7dMPM
};


my $client = WWW::YouTube::Download->new;


for my $url (@urls) {

	my $video_id = $url;
	$video_id =~ s/^.+embed\/(.+)\?.*/$1/;

	#タイトルの取得。
	my $title = $client->get_title($video_id);
	$title =~ s/[\?\/\>\<\/\:\;\~\{\}\'\"\[\]\*\|]//ig;			#"'widnowsでファイル名に使えない文字を消去
	$title = Encode::encode('cp932', decode_utf8($title));
	$title =~ s/[\?]//g;																		#utf8からsjisに変換できなかった文字を削除。

	print $video_id . "\n->" . $title . "\n";

	#mp4がすでにある場合は次へ。
	if (-f 'LT' . '_' . $title . '.mp4') {
		print "->skip!\n";
		next;
	}else{
		print "->download...\n";
	}

	#ダウンローーーード。
	$client->download($video_id, {
		filename => 'LT' . '_' . $title . '.mp4',
		fmt      => 18
	});
	print "->ok!\n";
}
