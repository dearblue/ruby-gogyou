# gogyou の更新履歴

## gogyou-0.2.5 (2015-10-20)

  * 可変長要素に続く要素の定義

    構造体定義中に可変長要素を置いた場合、続く要素を定義出来ませんでしたがこの制限を撤廃しています。

    この場合、可変長要素の可変長領域と、続く要素の領域以降が重なるため、部分的に union を用いたような動作となります。

  * ポインタ要素の実現 (実験的)

    非常に限定的ながらポインタ要素の定義を可能としました。
    詳細は pointer.ja.md を参照して下さい。


## gogyou-0.2.4 (2015-10-16)

  * 環境依存の型に対する結果の正確性を修正

    バイトオーダーが環境依存の型に対する値の取得・変更処理をより正確になるように修正しました。

    ただし代入時の CPU 負荷が二倍程度悪化しています。

  * いくつかの ruby 実装に対する修正

    ruby-2.0 はサポート対象としていたにもかかわらず gogyou-0.2.3 で require が失敗してしまった部分を修正しています。

    jruby、rubinius はこれまで確認すらしていませんでしたが、お遊び程度で確認しています
    (サポート対象となっていないことに注意して下さい)。

  * Gogyou::Accessor::Array#each の追加と Enumerable 化

    Gogyou::Accessor::Array#each を追加し、Enumerabale を include するように変更しました。

    Gogyou::Accessor::Array#each_with_index も追加してあります。

  * Fiddle::Pointer と FFI::AbstractMemory を構造体バッファオブジェクトとして利用可能に

    Fiddle::Pointer と FFI::AbstractMemory のインスタンスを構造体の
    バッファオブジェクトとして利用できるように機能を追加しました。

  * IEEE 754-2008 に対応した浮動小数点実数型を追加

    IEEE 754-2008 に対応した 16・32・64 ビット精度の浮動小数点実数に対する以下の型を追加しました。

    ``float16_t`` ``float16_swap`` ``float16_be`` ``float16_le``
    ``float32_t`` ``float32_swap`` ``float32_be`` ``float32_le``
    ``float64_t`` ``float64_swap`` ``float64_be`` ``float64_le``

  * 固定小数点実数の型名を追加

    16・32 ビット精度の固定小数点実数に対する以下の型を追加しました。

    ``fixed16q8_t`` ``fixed16q8_swap`` ``fixed16q8_be`` ``fixed16q8_le``
    ``fixed32q6_t`` ``fixed32q6_swap`` ``fixed32q6_be`` ``fixed32q6_le``
    ``fixed32q8_t`` ``fixed32q8_swap`` ``fixed32q8_be`` ``fixed32q8_le``
    ``fixed32q12_t`` ``fixed32q12_swap`` ``fixed32q12_be`` ``fixed32q12_le``
    ``fixed32q16_t`` ``fixed32q16_swap`` ``fixed32q16_be`` ``fixed32q16_le``
    ``fixed32q24_t`` ``fixed32q24_swap`` ``fixed32q24_be`` ``fixed32q24_le``

    これらは格納する時 (storeXXX) は固定小数点実数として処理されますが、ruby
    オブジェクトとして取り出す時 (loadXXX) は Float オブジェクトとして処理されます。

  * クラス・モジュール名の変更

    Gogyou::Primitives::Primitive を Gogyou::Primitive に変更しました。

  * いくつかの処理の効率を改善

  * その他問題の修正


## gogyou-0.2.3 (2015-5-17)

  * short、int、long、long long のバイト数が環境ごとの値として取得するようになっていなかった問題を修正
      * これらの型のバイト数 (sizeof) は Array#pack を用いてそれぞれ
        "S" "I" "L" "Q" を与えて取得しており、目的のためには本来 "!"
        を加える必要があります。
        これまではそうなっていなかったため、これを修正しています。
  * Gogyou::Accessor#inspect と Gogyou::Accessor#pretty\_print の改善
      * これらのメソッドは各フィールドの値を表示するように変更しました。
  * Gogyou::Accessor#size を Gogyou::Accessor#elementsize に変更
      * Gogyou::Accessor#size メソッドを Gogyou::Accessor#elementsize
        に名称変更しました。
      * Gogyou::Accessor#size メソッドは Gogyou::Accessor#elementsize
        の別名となりました。
  * Gogyou::Struct / Gogyou::Union クラスの追加
      * これらを親クラスとしたクラスを作成し、その中で ``struct`` / ``union``
        することで構造体の構築が行える機能を追加しました。
  * ``int24_t`` と ``int48_t`` 系列の型を削除
      * ネイティブレベルでは存在しない (であろう) 以下の型を削除しました。

        ``int24_t`` ``uint24_t`` ``int48_t`` ``uint48_t``
        ``int24_swap`` ``uint24_swap`` ``int48_swap`` ``uint48_swap``
      * ``int24_be`` ``int48_le`` などはこれまで通り利用できます。
  * その他の修正

## gogyou-0.2.2

*   ``Gogyou.define_typeinfo`` を追加
*   ``Gogyou.struct`` 内における、フィールド修飾子メソッド ``packed`` を追加
*   ``Extensions::String::Mixin#setbinary`` の引数の受け方を変更
*   その他微修正

## gogyou-0.2.1

*   ``Accessor::Array`` の ``#size`` と ``#bytesize`` が間違った値を返していた問題を修正
*   ``Accessor#size`` が存在しなかった問題を修正
*   その他微修正

## gogyou-0.2

*   バイナリデータに対する値の代入・取り出しとするために書き直し
*   共用体への対応を追加
*   フィールド修飾子メソッド ``const`` を追加
*   ``String`` と ``Integer`` に対するバイナリ操作メソッドを追加


## gogyou-0.1

*   初版
