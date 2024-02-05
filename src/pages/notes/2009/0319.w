---
title: Win9p
style: ../../../styles/global.css
pre: ../include/u.i
post: ../include/nav.i
---

.revision
2009年3月19日作成
=Win9p

shell namespace extensionとして9P拡張を作っていたのですが、
だんだんめんどくさくなってきたのであきらめます。
自戒の意味も込めて日記。

フォルダツリー部分が動くまでは作りました。
「ファイルを開く」などダブルクリックの動作は、
コンテキストメニューのデフォルトが動いているだけらしいので、
コンテキストメニューを作ればいけそう、までは調べましたが、
すでにある機能を実装するのは馬鹿らしいですね。
アイコンはともかくメニューの国際化はどうするんだとか、
他の拡張が入るとまた別の問題もあります。

そこで、さすがにデフォルトの動作をさせる機能があるんじゃないかと
調べていたのですが、まったく引っかからないのですね。
SHCreateDefaultContextMenu()なんかは、
名前からみれば正解かなあと思ったのですが、、
使い方が悪いのか空のメニューになりましたし。

現状までのソースを[win9p.zip|/plan9/src/win9p.zip]に置いておきます。
Python+pywin32で書きました。
Pythonに限らず、参考になるソースが見つからなかったのが残念でしたね。

こういうのはドライバとして書くべきなのかなあ。
でも64bit Windowsは証明書が無いとドライバ作れないですし、
証明書は個人で取得できませんからねえ、、
セキュリティ事情を考えても、この対応はばかじゃないかと思うのですけど。

この記事には追記があります。
*[Win9pその後|0524.w]
*[Windowsファイルシステム開発|0626.w]
