@include u.i
%title ファイルサーバのインストール

=ファイルサーバのインストール
.revision
2011年7月23日更新

	=はじめに

	これは、ファイルサーバ専用のカーネル構築記録です。
	dumpfs、ken fs、fs64等いろいろな呼び方がありますが、
	だいたい同じものを指しています。以下fsカーネルと呼びます。

	現在、fsカーネルはサポート外となり配布物から外されています。
	配布物から外れる前から使っているのでここに書いていますが、
	今から構築するには、あまりおすすめしません。
	ATAディスク周りにはバグがありますし、情報も少ないので。

	それでも、高い安定度は魅力的だなあ、と思います。
	フルSCSI化してからというもの、	
	ハードウェアトラブル以外で落ちたことがないですよ。

	なにはともあれ認証サーバが1台必要になります。
	注意する点としては、必ず[ilを組み込んで|il.w]ください。

	=ソースコードの取得

	現在、fsカーネルはサポート外になってしまったので、
	別途取得してこなければいけません。
	ソースコード一式は/n/sources/extra/fsにあるので
	普通にコピーしてもいいのですが、せっかくなのでreplica用の設定をします。
	以下の内容を$home/fs/dist/replica/instとして保存します。

	!% cat $home/fs/dist/replica/inst
	!#!/bin/rc
	!
	!# ken fs template.
	!# Assumes that distribution should be installed
	!# to /n/inst.
	!
	!s=/n/sources/extra/fs/replica
	!serverroot=/n/sources/extra/fs/fs
	!serverlog=$s/fs.log
	!serverdb=$s/fs.db
	!serverproto=$s/fs.proto
	!fn servermount { status='' } 
	!fn serverupdate { status='' }
	!
	!fn clientmount { status='' }
	!c=/n/inst/dist/replica
	!clientroot=/n/inst
	!clientproto=$c/fs.proto
	!clientdb=$c/client/fs.db
	!clientexclude=(dist/replica/client)
	!clientlog=$c/client/fs.log
	!
	!applyopt=(-t -u -T$c/client/fs.time)

	次に、$home/fs/dist/replica/client/fs.db(空でいい)を作成して、展開。
	ここではとりあえず、展開先を$home/fsとします。
	展開先を変えたい場合は、2行目のbindを変更してください。

	!% chmod +x $home/fs/dist/replica/inst
	!% echo -n >$home/fs/dist/replica/client/fs.db
	!% 9fs sources
	!% bind -c $home/fs /n/inst
	!% replica/pull -v /n/inst/dist/replica/inst

	しばらく待てば、$home/fs以下は次のようになります。

	!% lc $home/fs
	!9netics32.16k dev           emelie        ip            pc
	!9netics64.8k  dist          fs            mkfile        port
	!choline       doc           fs64          patch         run

	=時計合わせ

	fsカーネルでは、timezoneを変更するには
	ソースを書き換えなければできません。
	詳しくは[時計合わせ|../adm/timezone.w]を参照してください。

	=コンパイル

	以上で準備が整いましたので、コンパイルします。

	!% cd $home/fs/fs64
	!% mk

	これで、9fsfs64というカーネルができますので、
	続けてplan9.iniを用意します。
	etherの項は手持ちのカードに合わせてください。
	ソースコードのpc/etherif.cにネットワークカードの一覧が、
	pc/scsi.cにSCSIカードの一覧があります。

	!% cat plan9.ini
	!ether0=type=rtl8139
	!bootfile=fd!0!9fsfs64
	!nvr=fd!0!plan9.nvr

	または、9loadがカーネルを見つけられない場合、
	bootfileエントリを以下のようにすると解決するかもしれません。
	それでもnvrエントリは古い書き方をします。

	!bootfile=fd0!dos!9fsfs64

	用意ができたら、カーネルとまとめてフロッピーに書き込みます。
	単純にファイルをコピーしただけでは、
	ロードできない配置になってしまったりしますので、
	pc/bootfloppyを使います。

	!# 端末から直接書き込む場合
	!% pc/bootfloppy /dev/fd0disk plan9.ini 9fsfs64
	!
	!# フロッピーイメージを作成する場合
	!% pc/bootfloppy floppy.img plan9.ini 9fsfs64

	完成したらそれを使ってブートします。

	=ファイルサーバの構成

	サーバの設定を行います。
	ブート中にキーを押してconfigモードに入り、設定します。

	!config: config w0
	!config: service dryad
	!config: filsys main cw0f{w14w15}
	!config: filsys dump o
	!config: ipsntp 192.168.1.1
	!config: ip 192.168.1.23
	!config: ipgw 192.168.1.1
	!config: ipmask 255.255.255.0
	!config: ream main
	!config: end

	各行についてですが、serviceコマンドでホスト名を設定、
	filsysコマンドでファイルシステムの名前付けと
	ディスクの割り当てを行っています。
	上記の例では、mainファイルシステムとして、SCSIディスク0をキャッシュ、
	SCSIディスク14と15をミラーリングして擬似WORMとしています。

	.note
	fsカーネルでは、ルールさえ覚えてしまえば、
	簡単なコマンドでディスクを単純に連結したり、
	ストライピングしたりもできます。
	詳細は[fsconfig(8)]を読んでください。

	ipまわりは、そのままの意味。
	ネットワークカードが複数ある場合、1枚目はip0, ipgw0, ipmask0、
	2枚目はip1, ipgw1, ipmask1のように見えます。

	最後に、reamコマンドでファイルシステムを初期化です。
	このコマンドは、configモードを終えてから初期化を開始します。

	endコマンドでconfigモードを終えて通常運用モードに進みます。
	reamコマンドを発行した場合は、ここで初期化を行います。

	=ホストオーナーの設定とユーザの初期化

	しばらく待つとファイルサーバのプロンプトが表示されます。
	そこで、ユーザの初期化とファイルサーバパスワードの設定をします。
	passwdコマンドでは、認証ID、認証ドメイン、パスワードを聞かれますので、
	認証IDをbootes、認証ドメインとパスワードを
	認証サーバのbootesと同じ値に設定します。

	!dryad: users default
	!dryad: passwd

	このままではユーザ情報さえ保存できませんので、
	続けて、/adm/usersのほか、必須のファイルを作成します。

	!dryad: create /adm -1 -1 775 d
	!dryad: create /adm/users -1 -1 664
	!dryad: create /usr 10000 10000 775 d

	.note
	上記の、-1はadm、10000はsysと同等です。
	名前も使えたはずですが、ここではIDを使いました。

	準備ができたので、/adm/usersに保存します。
	保存コマンドは特に無く、ユーザの追加や削除が行われたタイミングで
	書き込みにいきますので、適当なユーザを追加してください。

	!newuser lufia

	.note
	users defaultコマンドは、メモリに初期テーブルがロードされるだけです。
	書き込みは行いません。

	ファイルサーバをマウントするだけならこれで完了です。
	クライアントのほうで以下のように使います。

	!% ramfs
	!% echo 'key proto=p9sk1 dom=mana.lufia.org user=glenda !password=xxxxx' >/tmp/factotum
	!% auth/secstore -p /tmp/factotum

	あとは、$home/lib/profileなどから9fsを使ってマウント。

	!9fs dryad

	これで/n/dryadにマウントされます。
	fsをルートファイルシステムとする場合は関連情報を参照。

	=トラブルシューティング

		=認証サーバからファイルサーバをマウントできない

		ファイルサーバのpasswdコマンドで設定するIDは、
		認証サーバと同じにしないといけないみたいです。
		通常、どちらもbootesにしておくのが無難です。
		もちろんパスワードも同じにします。

		=VMwareでNICを認識しない

		配布されているものは対応していません。
		パッチを当てたものが[etherigbe.c|
		../../src/etherigbe.c]にありますので差し替えて使ってください。

.aside
{
	=関連情報
	*[Sizka BASICへのインストール|sizka.w]
	*[分散システムのインストール|dist.w]
	*[VMware Playerにファイルサーバをインストール|
	../../../notes/2011/0723.w]

	=参考ページ
	*[Installing a Plan 9 File Server|
	http://www.plan9.bell-labs.com/wiki/plan9/Installing_a_Plan_9_File_Server/index.html]
}

@include nav.i
