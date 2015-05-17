# gogyou の更新履歴

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
