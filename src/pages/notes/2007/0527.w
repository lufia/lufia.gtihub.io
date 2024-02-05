---
title: ファイルサーバSCSI化(1)
style: ../../../styles/global.css
pre: ../include/u.i
post: ../include/nav.i
---

.revision
2007年5月27日作成
=ファイルサーバSCSI化(1)

先月のパッチを適用しても、dumpと同時に
キャッシュWORMディスクにアクセスがあったりすると不安定になったりしますね。
なので、Plan 9ファイルサーバでIDEディスクを使うのをあきらめて、
でもSCSIディスクは高い(キャッシュWORMならともかく)ので、[AEC-7726Q|
http://www.unitycorp.co.jp/products/acard/detail/scsi/aec7726q/aec7726q.html]を通販で購入しました。

ところがこいつがまた曲者で、2つ買ったのですが、
SCSI IDを設定するジャンパのところが
1つはマニュアルどおり14ピンで、設定すればそのとおりに使えました。
もう1つはなんだか10ピンしかありませんでした。
14ピンのほうは素直に認識されたのに、10ピンのほうはどうにもうまくいかず。
間違って送られてきたのかとも思ったのですが、
でも基盤にプリントされてるのは7726Qですから、さらに意味がわかりません。
googleで調べてもそれらしい記述は無いし。

購入先に確認をとったところ、
現在7726Qのロットは1.4と3.1が混在しているそうです。
今回引っかかったのは3.1のほうなので、マニュアルが追いついてないのでしょう。
でも同じ製品でピン数を変えるのはどうなんだろう。

初期不良の可能性もあるとのことなので、
返送して現在1週間経過。。。
さてさて、どうなることやら。
