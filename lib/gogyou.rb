#vim: set fileencoding:utf-8

# gogyou.rb
# - AUTHOR: dearblue <dearblue@users.osdn.me>
# - WEBSIZE: https://osdn.jp/projects/rutsubo/
# - LICENSE: same as 2-clause BSD License

#--
# this space block is for rdoc.                                         #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#                                                                       #
#++

#
# gogyou は構造体や共用体、多次元配列 (もどき) を扱うためのライブラリです。
#
# 原始的な型情報は Gogyou::Primitives で定義してあり、struct や union メソッド内で利用できる型を次の表に示します:
#
# ==== 型名
#
# * C の型名
#                               符号あり    符号なし
#                               ----        ----
#       char 型                 char        uchar
#                                           unsigned_char
#       short 型                short       ushort
#                                           unsigned_short
#       int 型                  int         uint
#                                           unsigned_int
#       long 型                 long        ulong
#                                           unsigned_long
#       long long 型            longlong    ulonglong
#                               long_long   unsigned_long_long
#       sizeof 型               ssize_t     size_t
#       ポインタ整数型          intptr_t    uintptr_t
#       float                   float       N/A
#       double                  double      N/A
#
# * バイトオーダー環境依存・ビット数環境非依存
#                                 バイトオーダー環境依存  バイトオーダー反転
#                                 符号あり    符号なし    符号あり      符号なし
#                                 ----        ----        ----          ----
#       8ビット整数型             int8_t      uint8_t     N/A           N/A
#       16ビット整数型            int16_t     uint16_t    int16_swap    uint16_swap
#       32ビット整数型            int32_t     uint32_t    int32_swap    uint32_swap
#       64ビット整数型            int64_t     uint64_t    int64_swap    uint64_swap
#       16ビット浮動小数点実数型  float16_t   N/A         float16_swap  N/A
#       32ビット浮動小数点実数型  float32_t   N/A         float32_swap  N/A
#       64ビット浮動小数点実数型  float64_t   N/A         float64_swap  N/A
#
# * バイトオーダー・ビット数環境非依存
#                                 ビッグエンディアン      リトルエンディアン
#                                 符号あり    符号なし    符号あり      符号なし
#                                 ----        ----        ----          ----
#       16ビット整数型            int16_be    uint16_be   int16_le      uint16_le
#       24ビット整数型            int24_be    uint24_be   int24_le      uint24_le
#       32ビット整数型            int32_be    uint32_be   int32_le      uint32_le
#       48ビット整数型            int48_be    uint48_be   int48_le      uint48_le
#       64ビット整数型            int64_be    uint64_be   int64_le      uint64_le
#       16ビット浮動小数点実数型  float16_be  N/A         float16_le    N/A
#       32ビット浮動小数点実数型  float32_be  N/A         float32_le    N/A
#       64ビット浮動小数点実数型  float64_be  N/A         float64_le    N/A
#
# * 固定小数点実数型 (ビット数環境非依存)
#
#                                               バイトオーダー環境依存          バイトオーダー環境非依存
#
#     16ビット固定小数点実数型(小数部8ビット)   fixed16q8_t   fixed16q8_swap    fixed16q8_be  fixed16q8_le
#     32ビット固定小数点実数型(小数部6ビット)   fixed32q6_t   fixed32q6_swap    fixed32q6_be  fixed32q6_le
#     32ビット固定小数点実数型(小数部8ビット)   fixed32q8_t   fixed32q8_swap    fixed32q8_be  fixed32q8_le
#     32ビット固定小数点実数型(小数部12ビット)  fixed32q12_t  fixed32q12_swap   fixed32q12_be fixed32q12_le
#     32ビット固定小数点実数型(小数部16ビット)  fixed32q16_t  fixed32q16_swap   fixed32q16_be fixed32q16_le
#     32ビット固定小数点実数型(小数部24ビット)  fixed32q24_t  fixed32q24_swap   fixed32q24_be fixed32q24_le
#
#
# ==== 利用者定義の型情報
#
# 型情報を利用者が定義して利用することが出来ます。
#
# 型情報オブジェクトは、次のメソッドを必要とします:
#
# * bytesize - 型のバイト数です。拡張要素を含んでいる場合は、最小となるバイト数です。
# * bytealign - 型のバイト位置境界です。uint32_t であれば、通常は 4バイトです。
# * aset(buffer, offset, value) - バッファに値を埋め込みます。
# * aref(buffer, offset) - バッファから値を取り出します。
# * extensible? - 型自身が拡張要素、または拡張要素が含まれているかの有無です。<tt>int a[0]</tt> のような可変個配列などの場合が当てはまります。
#
# 利用者定義の型情報は、struct / union / typedef メソッドの引数として与えることが出来ます。
#
#
# ==== example (ruby.h から struct RBasic と struct RString を模倣した場合)
#
# ポインタ型は実現できていないため、intptr_t で代用しています。
#
#   module MyRuby
#     extend Gogyou
#
#     typedef :uintptr_t, :VALUE
#
#     RBasic = struct {
#       VALUE :flags
#       VALUE :klass
#     }
#
#     RString = struct {
#       RBasic :basic
#       union -> {
#         struct -> {
#           long :len
#           intptr_t :ptr
#           union -> {
#             long :capa
#             VALUE :shared
#           }, :aux
#         }, :heap
#         char :ary, RSTRING_EMBED_LEN_MAX + 1
#       }, :as
#     }
#   end
#
#
# ==== "gogyou" の処理の分類とクラスの役割
#
# * 原始的な型情報の管理と登録
#   * Primitives - 原始的な型情報
#   * Model::TYPEMAP (hash) - 構造体構築時に利用できる、型名の登録
#   * 型情報オブジェクト - 型の情報を保持するオブジェクト
#
#     Primitives 内の定数として定義されているオブジェクトや、Accessor のサブクラスなどが当てはまります。
#
#     利用者定義の任意のオブジェクト (クラスやモジュールも含まれる) も、利用できます。
#
#     利用者定義の型情報オブジェクトについては、README を参照してください。
# * 構造体構築
#   * Model - 構造体・共用体の定義時にフィールド並びを管理するためのクラス
#
#     利用者が直接扱う必要はありません。
# * 構造体の実体の管理と参照・操作手段の提供
#   * Accessor - 構造体・共用体・配列を定義したあとの各クラスの親クラス
#
#     次のインスタンスメソッドが定義されます。
#
#     * #size - フィールドの要素数。配列の場合はその要素数。
#     * #bytesize - バイトサイズを返す。可変長配列を含んでいる場合は、現在の buffer と offset から計算された最大値を返す。
#     * #\<field> / #\<field>= - 構造体・共用体のフィールドへの参照・代入メソッド。配列の場合は定義されない。
#     * #[] / []= - 配列の要素への参照・代入メソッド。構造体・共用体の場合は定義されない。
#
# * 構造体のメモリイメージとなるバッファオブジェクト
#
#   構造体のバイト列を表現するオブジェクトのことです。
#
#   * String
#   * Fiddle::Pointer
#
module Gogyou
  Gogyou = self

  class PointerError < ::RuntimeError
  end

  class NullPointerError < PointerError
  end

  require_relative "gogyou/version"
  require_relative "gogyou/typespec"
  require_relative "gogyou/extensions"
  require_relative "gogyou/model"
  require_relative "gogyou/primitives"
  require_relative "gogyou/accessor"

  class Model
    TYPEMAP = {}

    Gogyou::Primitives.constants.each do |n|
      prim = Gogyou::Primitives.const_get(n)
      next unless prim.kind_of?(Gogyou::Primitive)
      TYPEMAP[prim.name.to_sym] = prim
    end

    TYPEMAP[:unsigned_char] = TYPEMAP[:uchar]
    TYPEMAP[:unsigned_short] = TYPEMAP[:ushort]
    TYPEMAP[:unsigned_int] = TYPEMAP[:uint]
    TYPEMAP[:unsigned_long] = TYPEMAP[:ulong]
    TYPEMAP[:unsigned_long_long] = TYPEMAP[:ulonglong]
    TYPEMAP[:long_long] = TYPEMAP[:longlong]
  end

  class Struct < Accessor::Struct
    def self.struct(&block)
      raise TypeError, "already defined struct" if const_defined?(:MODEL)

      # TODO: Accessor.define からコピペ。統一するべき。
      model = Model.struct(Model::TYPEMAP.dup, &block)
      const_set(:MODEL, model)
      const_set(:BYTESIZE, model.bytesize)
      const_set(:BYTEALIGN, model.bytealign)
      const_set(:EXTENSIBLE, model.extensible?)
      define_accessors(self, model)

      nil
    end

    private_class_method :struct
  end

  class Union < Accessor::Union
    def self.union(&block)
      raise TypeError, "already defined union" if const_defined?(:MODEL)

      # TODO: Accessor.define からコピペ。統一するべき。
      model = Model.union(Model::TYPEMAP.dup, &block)
      const_set(:MODEL, model)
      const_set(:BYTESIZE, model.bytesize)
      const_set(:BYTEALIGN, model.bytealign)
      const_set(:EXTENSIBLE, model.extensible?)
      define_accessors(self, model)

      nil
    end

    private_class_method :union
  end

  #
  # call-seq:
  #   struct { ... } -> accessor class
  #
  # 構造体を定義します。モジュールやクラス内で <tt>extend Gogyou</tt> しない(したくない)場合に利用することが出来ます。
  #
  # === example
  #
  #   class MyClass
  #     Type1 = Gogyou.struct {
  #       ...
  #     }
  #   end
  #
  def self.struct(&block)
    Model.struct(Model::TYPEMAP.dup, &block).create_accessor
  end

  def self.union(&block)
    Model.union(Model::TYPEMAP.dup, &block).create_accessor
  end

  #
  # call-seq:
  #   typeinfo(typename) -> typeinfo
  #   typeinfo(typeobj) -> typeinfo
  #
  # 型名に対する型情報子を取得します。
  #
  # 型情報子を渡した場合は、それをそのまま返り値とします。
  #
  # 型名が存在しないか、型情報子でない場合は nil を返します。
  #
  def self.typeinfo(type)
    case type
    when Symbol, String
      return nil unless type =~ /\A[_A-Za-z][_0-9A-Za-z]*\Z/
      Model::TYPEMAP[type.intern]
    else
      if Model.check_typeinfo(type)
        type
      else
        nil
      end
    end
  end

  #
  # call-seq:
  #   define_typeinfo(type, bytesize, bytealign, extensible, aref, aset) -> type
  #
  # ``type`` に対して、型情報子とするための特異メソッドである ``#bytesize`` ``#bytealign`` ``#extensible?`` ``#aref`` ``#aset`` を定義します。
  #
  # ``bytesize`` と ``bytealign`` には整数値、文字列、nil を与えます。
  #
  # ``extensible`` には真偽値、文字列、nil を与えます。
  #
  # ``aref`` には、引数として ``(buffer, offset)`` を受け取る Proc オブジェクト、文字列、nil を与えます。
  #
  # ``aset`` には、引数として ``(buffer, offset, value)`` を受け取る Proc オブジェクト、文字列、nil を与えます。
  #
  # これらの引数に文字列を与えた場合、メソッド定義コードとして直接埋め込まれます。
  #
  # ``bytesize`` と ``bytealign``、``extensible`` の引数はありません。
  #
  # ``aref`` の文字列内部で利用できる引数は ``buffer`` ``offset`` です。
  #
  # ``aset`` の文字列内部で利用できる引数は ``buffer`` ``offset`` ``value`` です。
  #
  # また nil を与えた場合は、対応するメソッドの定義を省略します。
  #
  # 常に ``type`` を返します。
  #
  def self.define_typeinfo(type, bytesize, bytealign, extensible, aref, aset)
    type.instance_eval do
      unless bytesize.nil?
        bytesize = bytesize.to_i unless bytesize.kind_of?(String)
        eval <<-EOM
          def bytesize
            #{bytesize}
          end
        EOM
      end

      unless bytealign.nil?
        bytealign = bytealign.to_i unless bytealign.kind_of?(String)
        eval <<-EOM
          def bytealign
            #{bytealign}
          end
        EOM
      end

      unless extensible.nil?
        extensible = (!!extensible).inspect unless extensible.kind_of?(String)
        eval <<-EOM
          def extensible?
            #{extensible}
          end
        EOM
      end

      unless aref.nil?
        if aref.kind_of?(String)
          eval <<-EOM
            def aref(buffer, offset)
              #{aref}
            end
          EOM
        else
          define_singleton_method(:aref, aref)
        end
      end

      unless aset.nil?
        if aset.kind_of?(String)
          eval <<-EOM
            def aset(buffer, offset, value)
              #{aset}
            end
          EOM
        else
          define_singleton_method(:aset, aset)
        end
      end
    end

    type
  end

  #
  # 構造体 (もどき) を定義します。
  #
  # 入れ子の構造体や共用体を定義するのはもちろん、無名構造体に無名共用体、多次元配列を定義することが出来ます。
  #
  # <tt>extend Gogyou</tt> したモジュール・クラス内で定義された構造体(もどき)のクラスは自動的に型情報を取り込みます。
  # サンプルコードの MyType3 の定義する際に使われる MyType1 と MyType2 に注目して下さい。
  #
  # === example
  #
  #   class MyClass
  #     extend Gogyou
  #
  #     MyType1 = struct {        # struct MyType1 {
  #       uint32_t :a             #   uint32_t a;
  #       uint32_t :b             #   uint32_t b;
  #       uint32_t :c, 8, 4       #   uint32_t c[8][4];
  #     }                         # };
  #
  #     MyType2 = struct {        # struct MyType2 {
  #       float :a, :b, :c, 8, 4  #   float a, b, c[8][4];
  #     }                         # };
  #
  #     MyType3 = union {         # union MyType3 {
  #       MyType1 :a              #   MyType1 a;
  #       MyType2 :b              #   MyType2 b;
  #     }                         # };
  #   end
  #
  #   t1 = MyClass::MyType1.new
  #   t2 = MyClass::MyType2.bind(String.alloc(MyClass::MyType2::BYTESIZE))
  #   t3 = MyClass::MyType3.bind(File.read("sample.bin", MyClass::MyType3::BYTESIZE, mode: "rb"))
  #
  def struct(&block)
    Model.struct(update_typemap__GOGYOU__, &block).create_accessor
  end

  def union(&block)
    Model.union(update_typemap__GOGYOU__, &block).create_accessor
  end

  #
  # call-seq:
  #   typeinfo(typename) -> typeinfo
  #   typeinfo(typeobj) -> typeinfo
  #
  # 型名に対する型情報子を取得します。
  #
  # 型情報子を渡した場合は、それをそのまま返り値とします。
  #
  # 型名が存在しないか、型情報子でない場合は nil を返します。
  #
  def typeinfo(type)
    case type
    when Symbol, String
      return nil unless type =~ /\A[_A-Za-z][_0-9A-Za-z]*\Z/
      update_typemap__GOGYOU__[type.intern]
    else
      if Model.check_typeinfo(type)
        type
      else
        nil
      end
    end
  end

  #
  # call-seq:
  #   typedef type, aliasname -> self
  #   typedef type, aliasname, *elements -> self
  #
  # ***limitation***: not usable the pointer.
  #
  # [type]
  #   This parameter can given a symbol or an object.
  #
  #   シンボル (または文字列) を与える場合、すでに定義されている型名である必要があります。
  #
  #   クラスオブジェクト (またはモジュールオブジェクト) を与える場合、`.aset` と `.aref` `.bytesize` `.bytealign` メソッドを持つ必要があります。
  #
  # [aliasname]
  #   定義する型名としてのシンボル (または文字列) を与えます。
  #
  # [elements]
  #   配列型の要素数を与えます。要素数は複数をとることが出来、最後の要素数として `0` を与えると任意個の要素数として定義されます。
  #
  def typedef(type, aliasname, *elements)
    Model.typedef(update_typemap__GOGYOU__, type, aliasname, *elements)
  end

  private
  def update_typemap__GOGYOU__(force = false)
    typemap = @typemap__GOGYOU__ ||= Model::TYPEMAP.dup
    constants.each do |n|
      obj = const_get(n)
      next unless Model.check_typeinfo(obj)
      if force
        typemap[n] = obj
      else
        typemap[n] ||= obj
      end
    end
    typemap
  end
end
