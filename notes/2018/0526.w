@include u.i
%title Safariのブックマーク同期が壊れた症状と対応

.revision
2018年5月26日作成
=Safariのブックマーク同期が壊れた症状と対応

	iOS 11.3にアップデートしてから、iOSのSafariでブックマークを操作すると、
	タイトルのないブックマークエントリが増えるようになりました。
	この項目は削除もできないし、開くこともできません。

	iOSのバグだろうからアップデートすれば解決するだろうと判断して、
	しばらくの間はMacのSafariからブックマークするように気をつけていました。
	だけどしばらく使っていると、Macから追加したものでも
	iCloudで同期すると消せない項目が作られるようになったり、
	本来ブックマークしたページとは全然関係ないページに書き変わったりと、
	ストレスを感じることが多くなってきました。

	手元で発生した事象は以下のような内容です。

	*iPhoneからブックマークすると空白のエントリが作られて消せない
	*iPhoneまたはMacからブックマークすると、iCloudと同期した時に意図しないページのブックマークで置き換えられる
	*Macでブックマークを操作すると、iCloudで同期した時にフォルダの名前やブックマークのURLが意図しないものに変わる

	どうやら、意図しないブックマークに置き換わる現象は、
	iPhoneのSafariで新規タブを開いた時に表示される「よく閲覧するサイト」の中から
	選ばれているようでした。フォルダの名前が変わる現象も、
	このリストに含まれるタイトルが使われていました。

	=うまくいった方法

	+MacのSafariでブックマークを書き出す
    +Mac側でブックマークを全て削除してiCloudに同期
    +同期を解除の後、もう一度同期させてブックマークが消えたことを確認
    +バックアップを復元してiCloudへ同期

	これでiCloud側のデータをリセットできるそうです。
	3の手順では、最初は同期し直すとタイトルのないフォルダが残っていたので、
	確実に消えるまで何度か試した方がいいかもしれません。

	また、ブックマークを復元すると「よく閲覧するサイト」も復活しますが、
	アイコンを長押しして「よく閲覧するサイト」も削除しておくといいでしょう。
	これで今のところ、ブックマークが壊れる現象は再現していません。

	リーディングリスト等はiCloudの同期を解除しても残っていたので、
	管理は別になっている気がします。
	今回はリーディングリストを残したまま作業をしましたが問題なさそうです。

	*[Safariブックマークの同期について|https://koubou-yuh.com/blog/?p=6738]
	
	=うまくいかなかった対策

	以下に、試してみたけれど改善しなかった対策をまとめます。
	あくまで私の場合であって、症状によっては改善する場合もあると思います。

	*[iPhoneのブックマークが消える(空白になる)不具合の直し方|
	https://iyusuke.net/iphone-bookmark-fix/]

	ブックマークの同期を外して、すぐに設定し直せば解決するという内容の記事。
	確かにこれをすると、消せないエントリは消えますが、
	次回以降のブックマーク追加時に状況は再現します。

	*[Safariのブックマークが空白になり消える不具合が報告|
	https://sbapp.net/appnews/app/upinfo/ios11/safari-bookmarks-79981]

	症状が発生したら、フォルダを作り直すといいよという記事。
	これを試した結果、移動した先でも同じ症状が発生しました。

	*[iPhoneでSafariのブックマークが空白・消える時の対処方法|
	https://sbapp.net/appnews/app/upinfo/ios11/safari-bookmark-81624]

	ブックマークの同期をしないように設定すると解決するよ、という記事。
	おそらくこの壊れる症状はiCloud側の問題だと思うので、
	この対策は結局のところ、次に同期したタイミングでまた壊れるように思います。

@include nav.i
