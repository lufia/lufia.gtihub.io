---
title: VMware ESXiの導入
style: ../../../styles/global.css
pre: ../include/u.i
post: ../include/nav.i
---

.revision
2012年9月9日作成
=VMware ESXiの導入

	だいぶ前に、ESXi 5.0を導入したので、
	その上でPlan 9サーバ群を動かすまでのメモをまとめました。
	Plan 9側のトラブルメモは別の記事にまとめるつもりです。こっちはESXi。

	=インストール

	なにはともあれ普通にインストール。
	MegaRAID 9240-4iに繋げたSSDにインストールしようと思ったら、
	インストールはできるけどブートできないという、よくわからない現象に。。
	同じハードウェア構成でWindowsを入れた時はふつうにブートしたので、
	何か分からないけどESXi側の問題な気がするなあ。

	とはいえ解決できなかったので、あきらめてUSBメモリを買ってきてそこへインストール。
	ESXi4の頃は、いろいろ設定しないとだめっぽい記事があったけど、
	ESXi5では普通のインストーラでも認識してくれるみたい。

	.note
	MegaRAIDのWebBIOSは、2chのRAIDカードスレによると、
	WebBIOSブート用のBIOSだけをメモリに置いておいて、
	ブート時には"WebBIOSが入った仮想ディスク"から起動するようです。
	なので、別のデバイスが優先になっているとWebBIOSに入れないとかなんとか。

	インストールが終わったら、コンソールからIPアドレスやらなにやらを設定。
	あとついでにSSHも有効にしておきます。

	=LSI Providerのインストール

	LSI 9240-4iを使っているので、せっかくだからとLSIProviderを入れてみます。
	ふつうに、VMwareのサイトからVMW-ESX-5.0.0-LSIProvider-xxxx.zipを
	ダウンロードしてきて展開、vibファイルだけをsshでESXiホストへ送ります。
	で、以下のコマンド実行。

	.console
	!$ esxcli software vib install -v /vmware-esx-provider-LSIProvider.vib

	.note
	esxcliに渡すvibファイルは、ルートからのフルパスでないとエラーになります。

	MegaCLIのESXi版はLSIのサイトから落とせるけれど、ESXi5にはlibstorelib.soが
	見つからなくて動きません。libstorelibを過去のESXiから拾っておくと動くけど、
	そこまでしなくてもいい気がしているので入れない方向でいます。

	=vSphere Clientをインストール

	ESXiとは別のWindowsマシンに、クライアントツールを入れます。
	ESXiホストにhttpで繋げばダウンロードできるので、ここは別に書くことない。。

	=VMwareの仮想ドライバパフォーマンス

	疑問だったのですけど、ESXiホストのネットワーク速度が1Gbで、
	仮想マシンのドライバがvlance(これは10Mb)の場合、どっちが有効なのかなあ、と。
	検索しても、同じハードウェアで物理と仮想のベンチマーク比較はいっぱいあるけれど、
	古い物理マシンをそのまま新しいハードウェアの仮想へもってきたとき、
	パフォーマンスが上がるのかはあまり見つからない。

	もし仮想デバイスの速度に制限されるなら、[Open Virtual Machine Tools|
	http://sourceforge.net/projects/open-vm-tools/files/open-vm-tools/]を
	移植するか、fsカーネルのe1000ドライバをまともな速度にするか、どちらかしないといけなくて
	めんどくさいなあと思っていたのですね。

	でも[ESX Server 3のパフォーマンスチューニングドキュメント|
	http://www-06.ibm.com/systems/jp/saiteki/pdf/esx_server3.pdf]によると、

	>たとえば、ESX ServerがエミュレートするAMD PCnetカードが定義により
	>10Mbpsであるため、サーバ上の物理カードが100Mbpsまたは1Gbpsであっても、
	>仮想マシン上のvlanceゲストドライバは10Mbpsの速度を報告します。
	>ただし、ESX Serverは10Mbpsには制限されず、物理サーバマシン上のリソースが
	>許すかぎり高速にネットワークパケットを転送します。

	とあるので、若干の劣化はあるでしょうけど今の使い方なら問題ない範囲かな。

	=VMDK

	クライアントからみると1つのvmdkにみえますが、
	sshからアクセスしてみたらじつは2つのファイルになっています。
	disk.vmdkというもろもろの設定を書いたテキストファイルと、
	disk-flat.vmdkというディスクファイル本体です。

	クライアントのストレージブラウザからはvmdkファイルの名前が変更できませんが、
	sshからなら普通に変更できるので、guest_1.vmdkみたいな名前がいやな人は、
	この2つのファイルをmvして、vmdkファイルに書かれている
	flat.vmdkファイルへの参照も変更すればいいです。

	=ゲスト間のシリアルポート接続

	物理にあったPlan 9システムは、fsカーネルのコンソールを、
	認証サーバがシリアルポート経由でログに記録していたので、
	どうにかしてゲスト間をシリアルポートで繋ぐ必要がありました。
	UPSみたいな外部機器とゲストを接続する記事はいくつかありましたが、
	ゲスト間をつなぐ記事は見つからなかったのでメモ。

	ゲストの構成からシリアルポートを追加します。
	このとき、名前付きパイプを選んで、名前は適当に(console0など)入力。
	無償版のライセンスでは、Ethernetを使った方法は使えないので無視します。

	で、接続先の設定はよく分かっていませんが、
	データを受け取る側を「サーバ」、送る側を「クライアント」にしました。
	具体的にはfs側は「クライアント」で、認証サーバが「サーバ」。
	接続先はどちらも「仮想マシン」。プロセスとの違いは分からない。

	=ブートフロッピーの作成

	これは普通に、Plan 9からpc/bootfloppyで作ればいいです。
	できたらvSphere Clientのファイルブラウザでアップロード。

	=過去のデータをvmdkに変換

	VMwareのConverterはBootCDが見つからなかったので、
	今回はvirt-p2vを使いました。

	まずはvirt-p2vをどうにかしてDVDに焼きます。
	できたら普通にブート。sshなどの設定をしていくのですが、
	仮想ディスクに変換するHDDを選ぶところで、Plan 9 fsのWORMディスクを
	選ぶと、何度やってもエラーになります。
	なのであきらめて、virt-p2vでエラーがでた画面から
	Fnキ(たしかF2)を押してシェルを実行。そのままシェルを使ってddしました。

	.console
	!# fdisk -l
	!(エラーが出るけど無視、容量だけ確認してターゲットを選ぶ)
	!# dd if=/dev/sdb | gzip -9 -c | ssh $user@$host "gzip -dc | dd bs=8192 of=/path/vmdisk/fworm.img"

	sshで接続するホストは、virt-p2vでssh設定テストした場所にすると楽です。

	ここからしばらく待てば、fworm.imgファイルができているはずです。
	HDDの速度やらネットワークやらに依存しますが、250GBを転送するのに
	だいたい2時間かかりました。

	次に、生のディスクファイルからvmdkへコンバートします。
	このときはqemu-imgを使いました。

	!$ qemu-img convert -f raw fworm.img fworm-flat.vmdk

	よく記事になっているコマンドでは、-f raw fowrm.img -O vmdk fworm.vmdkのように
	オプションでコンバート後の種類を指定していますが、
	なぜかこのオプションが効かずに、"-O"というファイル名になったりしました。
	たぶんfworm.imgの前にオプションを全部置けば動いたのでしょうけど、
	べつにわざわざ使わなくても判定してくれるので外してます。

	vmdkファイルが完成したら、それをESXiへ転送します。scpを使うよりは、
	gzipして転送したほうが早い気がするので、ddのときに使ったコマンドを
	そのまま使いました。

	.console
	!$ gzip -9 -c fworm-flat.vmdk | ssh $user@$esxihost "gzip -dc >/vmfs/volumes/disk1/plan9fs/fworm-flat.vmdk"

	必要なら、flatじゃないほうのvmdkファイルを修正して完成です。

	Plan 9ファイルサーバカーネルの場合、WORMだけ持ってくればいいのですが、
	そうすると、Cacheにある情報との齟齬でSuperblockが読めない系のエラーがでます。
	そのときはrecover mainすれば直前のdumpから普通に使えるようになります。

	=トラブルシューティング

		=健全性ステータスが全部、”不明”になった

		原因はよく分かりませんが、ESXiコンソールのTroubleshooting Optionsから、
		Restart Management Agentsで一部機能を再起動させると治りました。

		=LSI MegaRAID 9240-4iのバッテリに警告が出る

		健全性ステータスをみると、警告が出ていますが、
		もともと9240-4iはエントリモデルでBBUは付いていないので、
		そういうものらしいです。
