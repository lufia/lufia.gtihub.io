@include u.i
%title シェル

=シェル
.revision
2004年11月29日更新

	Plan 9唯一のシェルは/bin/rcです。
	それについてのメモ。

	= ファイル名の補完

	途中までファイル名を書いて、^f(control-f)キーを押すと、
	1つに限定される場合はそれに補完されて、
	複数ある場合は、候補が表示されます。

	単純な補完のようで、
	以下のように入力しても、[date(1)]が選ばれるわけではないです。

	!% dat^f

	次のものなら想像どおり。

	!% /bin/dat^f

.aside
{
	=参考ページ
	*[rc - the Plan9 shell|http://plan9.aichi-u.ac.jp/rc/index.html]
	*[rc - the Plan9 shell(2)|http://plan9.aichi-u.ac.jp/rc/rc2.html]
}

@include nav.i
