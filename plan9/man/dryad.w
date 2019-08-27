@include u.i
%title dryad

=dryad
	Cのライブラリまたは関数をテストするためのコードを自動生成します。

	=SYNOPSIS
	!dryad [file ...]

	=DESCRIPTION
		Cのライブラリをテストするためのコードを作成します。

		=基本フォーマット

		!%{
		!(必要なら)Cの宣言など
		!%}
		!定数や処理内容の定義
		!%%
		!テストデータ1
		!テストデータ2

		\%{から%}の間には、#includeや宣言文などを書きます。
		省略するとu.h, libc.h, regexp.hがincludeされますが、
		それ以外では指定しない限り、何も仮定しません。

		\%}以降から%%までの間には、テストのためのコードや、
		入力データのフォーマットを定義します。
		例えば入力データが:で区切られている場合には、
		\%setを使って次のように定義します。

		!%set FS ":"

		FSは変数名で、その次の""に囲まれたものが値です。
		また、%setできる変数は以下のものだけです。
		どちらもAwkのそれと同じルールです。

		:FS
		-field separator
		:RS
		-record separator

		テストのためのコードは、%try {}文を使って定義します。
		\{}の中にCのコードを書きます。{は%tryと同じ行になければいけません。
		そして}は、必ずそれだけの行に書いてください。

		\%tryの中では、$1,$2,...のような引数が使えます。例えば
		$1は最初の入力データに対応し、それらのどれもchar**型です。
		それらを使ってdrycheckを呼んでください。
		この関数は、[print(2)]と同じ書式を扱い、
		xpとfmtの結果が違えばエラーを報告します。

		!drycheck(char *xp, char *fmt, ...)

		\%tryの他にも、%begin,%endという文もあります。
		それらは%tryの前または後に実行し、引数はありません。

		\%%以降は入力データが続きます。

		=例外処理

		たとえばsysfatal(2)で終了した場合は、%rescueブロックを使えば
		調べることが可能です。エラー文字列は%rで表し、%tryと同様に、
		drycheckや$1, $2等が使えます。

	=EXAMPLE

	!%set FS ","
	!%set RS "\n"
	!%try {
	!	drycheck($2, "%x", atoi($1));
	!}
	!%%
	!32,20
	!17,11

	=SEE ALSO
	*[awk(1)]
	*[regexp(6)]

@include nav.i
