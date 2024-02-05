---
title: ILプロトコル
style: ../../../../styles/global.css
pre: ../../include/u.i
post: ../../include/nav.i
---

ILの論文をおおよそ意訳でやってみました。
それと、いろいろコメントやらリンクやらを張っていますが、
これらは勝手につけたものだったり、未訳だったりです。

.revision
2011年6月17日作成
=ILプロトコル

	Plan 9ファイルシステムプロトコル9PのRPCメッセージを転送するため、
	ILと呼ぶ新しいネットワークプロトコルを実装しました。
	これはコネクション型のプロトコルで、
	IPによってカプセル化されたデータグラムを運ぶ軽量なプロトコルです。
	ILは消失したパケットの再送と順序通りの配達を提供しますが、[フロー制御|
	http://net-juku.org/tcpip/tcpip102.html]と暗黙的な再送はしません。

	.note
	暗黙的な再送はおそらく、tcpでの[再送依頼を受けたらそれ以降を再送|
	http://www.7key.jp/nw/tcpip/tcp/tcp2.html]するところかな。
	ILはstateで受けたackの次にあるデータしか再送しないです。

	=導入

	Plan 9は、RPCリクエストとレスポンスメッセージに、
	メッセージ区切りがあり、順序保証を要求するプロトコル(9P)を使います。
	標準IPプロトコルのどれも、9Pメッセージの転送に適切ではありません。
	TCPは高いオーバーヘッドがあり、メッセージの区切りがありません。
	UDPは、単純でメッセージ区切りを持つとはいえ、順序保証がありません。
	我々は自分たちのシステムにIP, TCP, UDPを実装していたとき、
	9Pに適したプロトコルを選別しようとしました。
	要求する性質は:

	*信頼性のあるデータグラムサービス
	*順番通りの配達
	*IPネットワーク
	*シンプルで高パフォーマンス
	*柔軟なタイムアウト

	標準プロトコルには上記を満たすものが無かったので、
	IL(Internet Link)と呼ばれる新しいプロトコルを設計しました。

	ILは軽量な、IPの上位プロトコルです。
	これはコネクション指向で、メッセージの到着順を保証します。
	クライアントサーバ間でRPCメッセージを転送するために設計されたので、
	フロー制御はなく、構造は固有のフロー制約を含みます。
	.note
	{
		未解決メッセージ用の小さい窓は、多すぎる受信を防ぐ,
		バッファされつつあるところからの;
	}
	ウインドウからあふれたメッセージは捨てられ、再送されなければなりません。
	コネクションの確立時に接続の両端でシーケンス番号の初期値を生成するため、
	2wayハンドシェイクを使います; 続くデータメッセージは、
	受信側でバラバラになったメッセージを再並べ替えできるようにするため、
	シーケンス番号をインクリメントします。
	他のプロトコルとは対照的に、ILは暗黙的な再送が無効です。
	これは混雑したネットワークにおいて、
	暗黙的な再送によってより混雑させるのを防ぎます。
	TCPに似て、ILは往復時間によってタイムアウトを決定しますので、
	インターネットとローカルイーサネットのどちらでも上手に動きます。
	ネットワーク速度に適した肯定応答と再送の時間を見積もるために、
	往復時間(RTT; round-trip timer)を使います。

	=コネクション

	ILコネクションは接続している端から端へデータストリームを運びます。
	コネクションが維持されている間、
	片側に入ったデータは入れた順に逆側へ送られます。
	図1は、状態(円)とその変遷(弧)で
	コネクションの機能を描いたステートマシンです。
	それぞれの変遷は、水平線の上が変化の原因となったイベントで、
	下には、このときに受信または送信するメッセージを表しています。
	この論文の残りは、このステートマシンについて議論します。

	\<<図1>>, 原文をみてください。

	.note
	{
		snd(packet)は相手側へpacketを送信する。
		rcv(packet)は受信。

		packetはtype(seq, ack)かな？typeはsyncとかdataとか。
	}

	:ackok
	-any sequence number between id0 and next inclusive
	:!x
	-xを除くなんらかの値
	:-
	-なんらかの値

	ILステートマシンには、Closed, Syncer, Syncee,
	Established, Closingという5つの状態があります。
	コネクションは両端のIPアドレスとポート番号によって識別されます。
	アドレスはIPプロトコルヘッダにあり、
	ポート番号は18バイトのILヘッダにあります。
	コネクションごとに固有の変数は:

	:state
	-Closed, Syncer, Syncee, Established, Closingのどれか
	:laddr
	-32bitローカルIPアドレス
	:lport
	-16bitローカルILポート番号
	:raddr
	-32bitリモートIPアドレス
	:rport
	-16bitリモートILポート番号
	:id0
	-32bitシーケンス番号(ローカル側)
	:rid0
	-32bitシーケンス番号(リモート側)
	:next
	-ローカル側から送られる次のシーケンス番号
	:rcvd
	-正常に受信した最後のリモート側番号
	:unacked
	-まだACKを受け取っていない最初のシーケンス番号(ローカル側)

	接続は最初、未割当アドレスでClosedになっています。
	まだ接続されていないコネクションへメッセージが届くか、
	またはユーザが明確に接続すると、コネクションをオープンします。
	最初の場合、メッセージの送信元アドレスとポートがリモート側のそれになり、
	送信先はローカル側として処理します。
	このとき、コネクションの状態はSynceeです。2つ目の場合は、
	ユーザがローカルとリモート両方のアドレスとポートを明示します。
	コネクションの状態はSyncerになり、
	syncメッセージがリモート側に送られます。
	ローカルアドレスの正当な値はIPの実装によります。

	=シーケンス番号

	ILはデータメッセージを運びます。
	各メッセージはOSからのwrite命令1回分に対応し、
	それは32bitシーケンス番号により識別されます。
	コネクション両側の初期シーケンス番号はランダムで、
	最初のsyncメッセージで伝えます。
	番号は、続くデータメッセージごとにインクリメントされます。
	再送されたメッセージのシーケンス番号は、最初に送った番号です。

	=送信/再送

	.note
	{
		:acknowledgement
		-受信確認
		:acknowledge
		-承認
	}

	各メッセージは識別子(ID)と受信確認(ACK)という
	2つのシーケンス番号を持ちます。ACKは、
	リモート側で順序正しく受信を確認したシーケンス番号の最大値です。
	dataとdataqueryメッセージの場合、IDはそのシーケンス番号です。
	sync, ack, query, state, closeといったコントロールメッセージでは、
	IDは送ったデータメッセージの最大シーケンス番号より1大きい。
	.note
	{
		よく分かっていないけど、
		data(201, -)で送った後にsync, ackと続く場合、
		どちらもIDは202になるということなのかな。
		で、その後に送られるdataもIDは202ですが、
		おそらくここでインクリメント。次からIDは203になる。

		ソースを読むと、ilackq関数でunackedに追加するのですが、
		これはilkick関数(データの送信)からしか呼び出していないので
		たぶんあってる。nextを増やしているのもilkickだけだし、
		コントロールメッセージは受信したらすぐ応答しているし。
	}

	送信者はデータメッセージをdata型として送ります。
	ACKが返送メッセージに含まれています。
	データを受信してから200msec以内に返送していない場合、
	ackメッセージが送られるでしょう。

	IPでは、順序が入れ違ったり、混雑により消失したり、
	失敗したりするかもしれません。これを克服し、かつネットワークを
	混雑させないために、ILは改良した[go back nプロトコル|
	http://otsubo.info/contents/network/network06.html]を使います。
	平均RTT(round trip time)は、メッセージの送信と
	そのACKを受け取った遅延を計測することによって保たれます。
	いちども承認を受信していなければ、平均RTTを100msecだと仮定します。
	受信確認がまだされていないメッセージでいちばん古いものについて、
	RTTを4回過ぎても受信確認がない場合(図1ではrexmit timeout)は、
	ILはメッセージか受信確認のどちらかが消失したと判断します。
	このとき、送信者は最初の未承認メッセージだけをdataquery型で再送します。
	受信者はdataqueryを受信すると、順番に受信したデータメッセージの
	最大ACKをstateメッセージで応答します。
	これはたぶん、再送されたメッセージのシーケンス番号、または
	(受信者が今までにため込んでいるメッセージの順序が狂ったなら)
	より大きい正常に受信したシーケンス番号でしょう。
	受信者が、順序が狂ったメッセージを保存するかどうかは実装によります。
	我々の実装では前方向に10パケットため込みます。
	送信者はstateメッセージを受信したとき、
	すぐに次の未承認なメッセージをdataquery型で再送します。
	これは全てのメッセージが承認されるまで続けられます。

	.note
	{
		:sync
		-最初の2wayハンドシェイク
		:data
		-ふつうのデータパケット
		:dataquery
		-ひとつのシーケンス番号だけ再送要求
		-stateを返す
		:ack
		-ack
		:query
		-データを持たないdataquery
		:state
		-正常受信した最大シーケンス番号パケット
		-未承認パケットがあればdataqueryを返す
		:close
		-close
	}

	もし、dataqueryの後にACKが届かないなら、
	タイムアウトの後、送信者はdataqueryメッセージの再送を続けます。
	再送の間隔は指数関数的に増大します。
	最後に受信してから300秒経過した後(図1のdeath timeout)、
	送信者はあきらめて接続が切れたと判断します。

	再送は、Syncer, Syncee, Close状態でも起こります。
	その再送間隔はデータメッセージと同等です。

	=Keep Alive

	切れた接続は発見され、リソースを消費しないように取り壊さなければなりません。
	生きているシステムだとしても、これ以上データも受信確認も送らないなら、
	今までに述べたプロトコルは、これらの接続を発見しません。
	.note
	{
		このあたり翻訳があやしい。
	}
	したがって、Established状態において、最後に送信してから6秒間、
	他にメッセージが無いなら、queryを送ります。
	受信者はいつでも、stateメッセージでqueryに応答します。
	もし最後に受信してから30秒間メッセージが届かなければ、
	接続は閉じられます。これは図1に描かれていません。

	=バイトオーダー

	すべての32bitと16bit数は[ネットワークバイトオーダー|
	http://www.atmarkit.co.jp/icd/root/72/116970472.html]です。

	=フォーマット

	以下は、IPオプションを無いものとして、
	C言語で記述したIP+ILヘッダです。

	.c
	!typedef unsigned char byte;
	!struct IPIL
	!{
	!	byte vihl;	/* バージョンとヘッダ長 */
	!	byte tos;	/* type of service */
	!	byte length[2];	/* パケット長 */
	!	byte id[2];	/* Identification */
	!	byte frag[2];	/* フラグメント情報 */
	!	byte ttl;	/* Time to live */
	!	byte proto;	/* プロトコル */
	!	byte cksum[2];	/* ヘッダのチェックサム */
	!	byte src[4];	/* IP送信元 */
	!	byte dst[4];	/* IP送信先 */
	!	byte ilsum[2];	/* ヘッダを含めたチェックサム */
	!	byte illen[2];	/* パケット長 */
	!	byte iltype;	/* パケットタイプ */
	!	byte ilspec;	/* special */
	!	byte ilsrc[2];	/* 送信元ポート番号 */
	!	byte ildst[2];	/* 送信先ポート番号 */
	!	byte ilid[4];	/* シーケンス番号 */
	!	byte ilack[4];	/* ACK */
	!};

	データはヘッダのすぐ下です。
	ilspecは将来のために予約されているフィールドです。

	チェックサムはilsumとilspecを0にしたうえで計算されます。
	これは標準IPチェックサムで、
	that is, the 16-bit one's complement of the one's complement sum of
	all 16 bit words in the header and text.
	もしメッセージのヘッダとテキストのバイト数が奇数なら、
	上位バイトを0で詰めた16bit数として扱います。

	チェックサムはcksumからデータの終わりまでをカバーします。

	有効なiltype値は:

	.c
	!enum {
	!	sync=		0,
	!	data=		1,
	!	dataquery=	2,
	!	ack=		3,
	!	query=		4,
	!	state=		5,
	!	close=		6,
	!};

	illenフィールドはILヘッダとデータのバイト数です。

	=Numbers

	IL用のIPプロトコル番号は40。
	割り当てられたILポート番号:

	:7
	-echo all input to output
	:9
	-discard input
	:19
	-send a standard pattern to output
	:565
	-send IP addresses of caller and callee to output
	:566
	-Plan 9認証プロトコル
	:17005
	-Plan 9 CPUサービス, データ
	:17006
	-Plan 9 CPUサービス, notes(シグナルのようなもの)
	:17007
	-Plan 9 exported file systems
	:17008
	-Plan 9ファイルサービス
	:17009
	-Plan 9 remote execution
	:17030
	-Alef Name Server

	=参照

	*The Use of Name Spaces in Plan 9
	*RFC791, Internet Protocol
	*RFC793, Transmission Control Protocol
	*RFC768, RFC768, User Datagram Protocol

.aside
{
	=関連情報
	*[原文(PDF)|https://9p.io/sys/doc/il/il.pdf]
	*[il.cを読む|../../../notes/2011/0618.w]
	*[カーネルにilを組み込む|../inst/il.w]
}
