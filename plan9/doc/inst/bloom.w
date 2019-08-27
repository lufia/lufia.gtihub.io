@include u.i
%title bloomフィルタ付きventiを作る

=bloomフィルタ付きventiを作る
.revision
2015年5月4日更新

	現在の(ベル研が配布している)インストールCDは、
	ventiのbloomフィルタを作成しません。
	インストールが終わってからbloomフィルタを追加するのは
	ディスクを追加したりと面倒なので、インストール時に作っておきます。

	=インストール中で

	CDイメージからブートしたら、prepdiskまではそのまま進めます。
	prepdiskまで進んだら、別のwindowを開いてprepdiskを手動実行します。

	!% disk/prep -a 9fat -a nvram -a arenas -a isect -a bloom -a fossil -a swap /dev/sdC0/plan9
	!% disk/prep -p /dev/sdC0/plan9 >/dev/sdC0/ctl

	終わったらwindowを閉じて、prepdiskを実行しますが、
	prepdiskは終わっているので、そのままqでprepdiskを抜けて次へ進めます。

	=初回ブートのあと

	/dev/swapの値を以下に設定して、bloomsizeを計算します。

	!#!/usr/bin/awk -f
	!
	!BEGIN {
	!	# cat /dev/swap
	!	pgsize = 4096 # /dev/swapのpagesize
	!	userused = 1424 # /dev/swapのuser左側
	!	userpgs = 458749 # /dev/swapのuser右側
	!
	!	userfree = (userpgs-userused)*pgsize
	!	bloomsize = 2 ^ int(log(userfree/1024/1024*20/100*1/3) / log(2))
	!	print bloomsize
	!}

	上記結果をfmtbloomの-sオプションに与えてフォーマットします。

	!% venti/fmtbloom -s 64m /dev/sdC0/bloom

	あとはventi.confにbloomを設定します。

	!% venti/conf /dev/sdC0/arenas >/tmp/venti.conf
	!(isectとarenasの間あたりに追加)
	!bloom /dev/sdC0/bloom
	!% venti/conf -w /dev/sdC0/arenas /venti.conf

@include nav.i
