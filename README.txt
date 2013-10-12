= About gogyou

ゴギョウ (御形) は、バイナリ文字列にパックまたはアンパックする構造体クラスを定義する ruby のライブラリです。


gogyou は ruby 向けに作成され、バイナリデータと構造体との変換を容易にするためのライブラリです。名前は春の七種の一つ『ごぎょう』からとりました。

ruby に組み込まれている String#unpack / Array#pack は Struct クラスとの関係性はまったくありません。対応付けをするのも自力で書く必要があり、パックフォーマットと変数の関係性の直接的な結びつきも分かり難いものです。

gogyou ライブラリはこの負担を軽減することとともに、視認性の向上を目的に作成されました。

ただし、rdoc の適用対象とは (やっぱり) なりません。必要であれば定数定義の前に (非常に長い) コメントを入力するか、クラスを定義してそこで rdoc を記述するのがいいでしょう。


== 実行速度面では不利

構造体の定義は結構重い処理 (数ミリ秒) になっています。しかし、アプリケーション初期化時において各構造体ごとに一度だけ処理されるため、気になることはあまりないと思います。

そしてやはり pack / unpack は自力で記述した場合と比べれば重くなりますが、手書きでゴリゴリ書くかゴギョウで楽するかを天秤に掛けてみてください。


== 基本

gogyou ライブラリを用いることによって以下のように記述できます。

  require "gogyou"

  Sample = Gogyou.struct do
    uint32_t :data1     # C の uint32_t (32ビット無符号整数値) を定義
    int16_t  :data2, 2  # C の int16_t (16ビット符号付き整数値) を要素数 2 で定義
    uint64_t :data3     # C の uint64_t (64ビット無符号整数値) を定義
    uint8_t  :data4, 2  # C の uint8_t (8ビット無符号整数値) を要素数 2 で定義
    char     :data5, 2  # C の char (8ビット符号付き整数値) を要素数 2 で定義
    ustring  :data6, 4  # NULL 終端の UTF-8 文字列を定義 / 文字列長は 4 / 要素数 1
    binary   :data7, 8  # ASCII-8BIT 文字列を定義 / 文字列長は 8 / 要素数 1
  end

  p Sample::PACK_FORMAT # => "I s2 Q C2 c2 Z4 a8" # 実際には空白は含まれません
  p Sample::SIZE # => 32

Sample クラスは Struct クラスのインスタンス (ruby から見ればクラスオブジェクト) で、PACK_FORMAT、SIZE の定数が定義され、.unpack / .pack メソッドが定義されます。

つまり上記の例であれば、

  sample = Sample.unpack(data_sequence)
  data_sequence = sample_data.pack

というようなメソッド呼び出しができる Sample クラスが定義されることになります。

== Gogyou.struct ブロック内は self コンテキストが切り替わる

Gogyou.struct を呼び出すときに渡すブロックは、そのブロック内での self コンテキストが切り替わります。

ブロックの外で呼び出せるメソッドがブロック内で呼び出せないもしくは意図しない結果になる場合は、このことが原因と見ると対策しやすいかもしれません。

こんな (一見横暴な) 仕様になっているのは、ブロックパラメータの受け取りと型名を記述する際の変数の記述という煩わしさから開放するという目的を達成させるためです。

実装としては Gogyou.struct メソッド内で instance_eval にブロックをそのまま渡しています。

== 各要素は境界上に配置される

それぞれの要素のバイトオフセットは C 言語の構造体に倣って、各要素の境界上に配置されます。

  Sample = Gogyou.struct do
    uint8_t  :data1 # 0000h に配置。幅は1。
    uint16_t :data2 # 0002h に配置。幅は2。
    uint8_t  :data3 # 0004h に配置。幅は1。
    uint32_t :data3 # 0008h に配置。幅は4。
    uint64_t :data3 # 0010h に配置。幅は8。
  end

  p Sample::PACK_FORMAT # => "C x S C x3 L x4 Q"

== 入れ子になった構造体

入れ子の構造体表記も可能です。入れ子の入れ子のさらに・・・みたいなやつも記述可能ですが、展開がその分遅くなります。

  Sample = Gogyou.struct do
    struct :ref1 do   # 入れ子の構造体。名無しクラス (Struct を祖に持つクラス) を返します。
      uint32_t :data1 # ref1.data1 で参照できます。
      uint32_t :data2
    end

    int :data3
  end

  p Sample::PACK_FORMAT # => "a8 i"


== エンディアン指定

エンディアン指定も可能です。サフィックスが『_t』で終わるやつは基本的に『_le』でリトルエンディアン、『_be』かサフィックスなしでビッグエンディアンになります。

  Sample = Gogyou.struct do
    uint32_t :data1  # 動作環境に依存。
    uint32_be :data2 # 常にビッグエンディアン (ネットワークエンディアン) / パックフォーマットでは『N』と同等。
    uint32_le :data3 # 常にリトルエンディアン (バックスエンディアン) / パックフォーマットでは『V』と同等。
  end

  p Sample::PACK_FORMAT # => "L N V" # 実際は環境によって変わってきます

== 境界上に配置されない要素

型名の後ろに感嘆符『!』をつけるとその型の境界上に配置されるのを抑制します。GCC でいうところの "__attribute__((__packed__))" が付いている構造体です。

  Sample = Gogyou.struct do
    uint8_t!  :data1, 3 # 0000h に配置。幅は1。
    uint16_t! :data2, 3 # 0003h に配置。幅は2。
    uint32_t! :data3, 3 # 0009h に配置。幅は4。
  end

  p Sample::PACK_FORMAT # => "C3 S3 L3"
  p Sample::SIZE # => 21

== 境界指定

"alignment" (短縮して "align" も利用可) で、次の要素の配置が指定境界に来るようになります。ただし要素自体の境界配置が無効化さるわけではないため、そのことも含めて強制させるためには『!』を用いる必要があります。

  Sample = Gogyou.struct do
    uint8_t :data1  # 0000h に配置。
    alignment 16    # 穴埋め。次の要素は0010hに配置される。
    uint32_t :data2 # 0010h に配置。
  end

  p Sample::PACK_FORMAT # => "C x15 L"

  Sample2 = Gogyou.struct do
    uint8_t :data1  # 0000h に配置。
    alignment 15    # 穴埋め。次の要素は000fhに配置される。
    uint32_t :data2 # 境界配置のため、0010h に配置。
  end

  p Sample2::PACK_FORMAT # => "C x14 x L"

== 任意幅の穴埋め

"padding" で、任意幅の穴埋めができます。

  Sample = Gogyou.struct do
    uint8_t :data1  # 0000h に配置。
    padding 8       # 穴埋め。次の要素は 0009h に配置される。
    uint32_t :data2 # 4バイト境界上の 000Ch に配置。
  end

  p Sample::PACK_FORMAT # => "C x8 x3 L"

== 型の別名定義

"typedef" で、C でいう型の別名が定義できます。

  Sample = Gogyou.struct do
    typedef :uint, :HANDLE # 以降 HANDLE を使うと uint を指定したことになる

    uint8_t :data1, 3
    HANDLE :data2
  end

  p Sample::PACK_FORMAT # => "C3 x I"

入れ子定義内でも親で定義した typedef は有効です。

  Sample = Gogyou.struct do
    typedef :uint, :HANDLE

    HANDLE :data1
    struct :dataset do
      HANDLE :data1   # この HANDLE は親スコープで typedef したものが継承されたものです。
      HANDLE :data2
    end
  end

また任意のクラスを指定することで外部クラスをブロック内で定義することができるようになります。

  Sample = Gogyou.struct do
    typedef MD5 :MD5 # 以降 MD5 で MD5 クラスが展開と格納を行う

    MD5 :md5
  end

この MD5 クラス (モジュールでも可) は、pack / unpack メソッドを持ち、SIZE 定数 (バイト数。MD5 なので 16) を持つ必要があります。

  class MD5
    SIZE = 16

    def self.pack(obj)
      ...
      # string オブジェクトを返さなければならない
      # bytesize は SIZE と等しくなければならない
    end

    def self.unpack(str)
      # str は SIZE 定数で指定した分量のバイナリ文字列
      ...
      # 展開したオブジェクトを返す
    end
  end


== 型名一覧

それぞれ正規表現に沿った見方をしてください。。。 (ちょーみづれー)

- バイナリ列 (環境非依存): binary
- UTF-8 文字列 (環境非依存): ustring
- 整数 (環境非依存): u?int8_t, u?int16(_be|_le)!?, u?int32(_be|_le)!?, u?int64(_be|_le)!?
- 浮動少数 (環境非依存): float(_be|_le)!?, double(_be|_le)!?
- 整数 (環境依存 : ビット数、エンディアン): u?char, u?short!?, u?int!?, u?long!?, u?longlong!?
- 整数 (環境依存 : ビット数、エンディアン): s?size_t!?, u?intptr_t!?
- 整数 (環境依存 : エンディアン): u?int16_t!?, u?int32_t!?, u?int64_t!?
- 浮動少数 (環境依存 : ビット数、エンディアン): float!?, double!?

