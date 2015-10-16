# gogyou (ゴギョウ)

The gogyou is a library that provides auxiliary features of binary data operation for ruby.

The C-liked struct, union and multidimensional array definition are posible in ruby syntax.

"gogyou" is means "Gnaphalium affine" in japanese.

----

(in Japanese)

gogyou は、バイナリデータ操作の補助機能を提供する、ruby 拡張ライブラリです。

ruby 構文による、C 言語の構造体・共用体・多次元配列 (もどき) の定義が可能です。

名称は春の七種の一つである『ゴギョウ』から取りました。

----

  * Product Name (名称): gogyou (ゴギョウ / 御形 / Gnaphalium affine)
  * Author (制作者): dearblue &lt;dearblue@users.osdn.me&gt;
  * Distribute License (頒布ライセンス): 2-clause BSD License (二条項 BSD ライセンス)
  * Software Quarity (ソフトウェア品質): EXPERIMENTAL
  * User (想定利用者): Rubyist
  * Release Number (リリースナンバー): 0.2.4
  * Memory Usage (使用メモリ量): 2 MB +
  * Installed Size (インストール容量): under 1 MB
  * Project Page: &lt;https://osdn.jp/projects/rutsubo/&gt;
  * Support Ruby: ruby-2.0+ &lt;http://www.ruby-lang.org/&gt;

## Example

ruby/ruby.h の ``struct RBasic`` と ``struct RObject`` を gogyou を用いて次のように記述出来ます
(ポインタの定義はできていないため、``uintptr_t`` で置き換えています):

``` ruby:ruby
require "gogyou"

module MyRuby
  extend Gogyou

  ROBJECT_EMBED_LEN_MAX = 3

  typedef :uintptr_t, :VALUE

  RBasic = struct {
    VALUE :flags
    const VALUE :klass
  }

  RObject = struct {
    RBasic :basic
    union -> {
      struct -> {
        long :numiv
        uintptr_t :ivptr
        uintptr_t :iv_index_tbl
      }, :heap
      VALUE :ary, ROBJECT_EMBED_LEN_MAX
    }, :as
  }
end
```

``extend Gogyou`` して呼ばれた ``struct`` は、構築した構造体の無名クラスを返します。

この無名クラスを定数に代入すれば、ruby の一般的なクラスと同様に扱うことが出来ます。

``RObject`` のインスタンスは次のように (C 言語のそれや、ruby の他のオブジェクトと相違無く) 扱うことが出来ます。

また、ruby がもつ ``p`` メソッドや ``pp`` メソッドでわかりやすく表示されます (gogyou-0.2.3 にて追加)。

定義した構造体のインスタンスを作成する場合、文字列だけではなく Fiddle::Pointer や FFI::AbstractMemory インスタンスの指定も可能です (gogyou-0.2.4 にて追加)。

``` ruby:ruby
obj = MyRuby::RObject.new
# OR: obj = MyRuby::RObject.bind("0123456789abcdef" * 2000)  # given any string
# OR: require "gogyou/fiddle"
#     obj = MyRuby::RObject.bind(Fiddle::Pointer.malloc(MyRuby::RObject.bytesize))
# OR: require "gogyou/ffi"
#     obj = MyRuby::RObject.bind(FFI::MemoryPointer.new(MyRuby::RObject.bytesize))

obj.basic.flags = 1234567890
(obj.basic.klass = 0xaaaaaaaa) rescue p $!  # => EXCEPTION! klass field is immutable

obj.as.heap.numiv = 0x55555555
p obj.as.ary[0]  # => 0x55555555  # same address as union field

obj.as.heap.ivptr = 1234567890
p obj.as.heap.ivptr     # => 1234567890
tmp = obj.as.heap       # get a middle field accessor
tmp.ivptr = 0x44444444
p obj.as.heap.ivptr     # => 0x44444444

# following results are in little endian 64 bit system
require "pp"

pp obj.bytesize     # => 40
pp obj.to_buffer    # => "xV4\x12\0\0\0\0\0\0\0\0\0\0\0\0UUUU\0\0\0\0DDDD\0\0\0\0\0\0\0\0\0\0\0\0"
pp obj              # => #<MyRuby::RObject
                    #      basic=
                    #       #<MyRuby::RBasic
                    #         flags=1234567890,
                    #         klass=0>,
                    #      as=
                    #       {heap={numiv=1431655765, ivptr=1145324612, iv_index_tbl=0},
                    #        ary=[1431655765, 1145324612, 0]}>
```


## About features (機能について)

  * Support A C-liked struct and union (with nested and anonimous containers)

    C に似た構造体・共用体に対応 (無名の入れ子構造も可能)

    ``` ruby:ruby
    X = Gogyou.struct {             # struct X {
      int :a                        #     int a;
      float :b                      #     float b;
      double :c                     #     double c;
      union {                       #     union {
        struct -> {                 #         struct {
          float :x, :y, :z, :w      #             float x, y, z, w;
        }, :d, 4                    #         } d[4];
        const struct -> {           #         const struct {
          int32_t :x, :y, :z, :w    #             int x, y, z, w;
        }, :e, 4                    #         } e[4];
      }                             #     };
      struct {                      #     struct {
        int :u, :v, :s, :t          #         int u, v, s, t;
      }                             #     };
    }                               # };
    ```

  * Support multidimensional arrays

    多次元配列に対応

    ``` ruby:ruby
    X = Gogyou.struct {                 # struct X {
      char :name, 64, 4                 #     char name[64][4];
      char :a, :b, 16, :c, 4, 8, :d     #     char a, b[16], c[4][8], d; // mixed definition
    }                                   # };
    ```

  * Alias types by `typedef` (with array)

    `typedef` による型の別名定義 (配列も可能)

    ``` ruby:ruby
    module MyModule
      extend Gogyou

      typedef :float, :vector3f, 3  # => C: typedef float vector3f[3];

      X = struct {                  #       struct X {
        vector3f :a                 #           vector3f a;
        vector3f :b, 4              #           vector3f b[4];
      }                             #       };
    end
    ```

  * Support packed struct liked GCC ``__attribute__((packed))``

    GCC の ``__attribute__((packed))`` に似た、パックされた構造体に対応

    by C:

    ``` c:c
    struct X
    {
        char a;
        int b;
    } __attribute__((packed));
    ```

    by ruby:

    ``` ruby:ruby
    X = Gogyou.struct {
      packed {
        char :a
        int :b
      }
    }
    ```

  * Appended bit operation for Integer

    Integer に対する追加のビット操作

  * Appended binary operation for String

    String に対する追加のバイナリ操作


## How to usage (使い方)

最初に gogyou を読み込みます。

``` ruby:ruby
require "gogyou"
```

構造体(又は共用体)を定義する方法はいくつかあり、小さいながらもそれぞれに特徴が異なります。

 1. クラスやモジュールの中で ``extend Gogyou`` して、``struct`` (または ``union``) をブロック付きで呼び出し、その戻り値を定数に代入する

    ``` ruby:ruby
    module MyModule
      extend Gogyou

      TypeA = struct {
        int :a
      }
    end
    ```

    特徴:

      * MyModule の中で ``typedef`` を使うことが出来る
      * extend したモジュール内で struct した型名を typedef することなく利用することが出来る

 2. Gogyou.struct (または Gogyou.union) をブロック付きで呼び出し、その戻り値を定数に代入する

    ``` ruby:ruby
    TypeA = Gogyou.struct {
      int :a
    }
    ```

    特徴:

      * Gogyou モジュールを ``extend`` する必要がない
        (``extend`` するためのモジュール/クラスが不要)

 3. Gogyou::Struct (または Gogyou::Union) を親クラスとしてクラスを定義し、その中で ``struct`` (または ``union``) をブロック付きで呼び出す
    (gogyou-0.2.3 にて追加)

    ``` ruby:ruby
    class TypeA < Gogyou::Struct
      struct {
        int :a
      }
    end
    ```

    特徴:

      * 構造体 (共用体) の定義とメソッド定義を同じ ``class`` ブロックの中で定義することが出来る
      * Gogyou モジュールを ``extend`` する必要がない

以下の利用例では、(1)の方法を元に説明しています。

### Define struct (構造体の定義)

クラスやモジュールの中で ``extend Gogyou`` してから ``struct`` をブロック付きで呼び出します。

**このブロックは struct 内部で生成されるオブジェクトが instance\_exec するときにそのまま渡されます。*self が切り替わることに注意*して下さい。**

フィールド名はシンボル (または文字列) で与えます。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeA = struct {
    int :a
  }
end
```

これで int 型一つのフィールドからなる構造体(もどき)のクラスが TypeA として定義されました。

`struct` は定義した無名クラスを返すため、利用者側で定数に代入することで構造体名が定義されるわけです。


### Define array in struct (配列の定義)

配列として定義する場合は、フィールド名に続く引数として整数値を与えます。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeA1 = struct {
    int :b, 4  #  => C: int b[4];
  }
end
```

多次元配列の場合は、連続して整数値を与えます。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeA2 = struct {
    int :c, 8, 4, 2  #  => C: int c[8][4][2];
  }
end
```

配列の場合でも、複数のフィールドを連続してまとめることが出来ます。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeA3 = struct {
    int :a, :b, 4, :c, 8, 4, 2  #  => C: int a, b[4], c[8][4][2];
  }
end
```


### Define nested struct (入れ子になった構造体の定義)

入れ子構造体を定義するには、struct の内部で struct を使えばいいだけです。

struct の最初の引数にブロックを与えること以外は、先に述べた通常のフィールド定義と同じです。

コメントは C 言語で記述した場合の対比としてあります。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeB = struct {      #  struct TypeB {
    struct -> {         #      struct {
      int :a, :b        #          int a, b;
    }, :n, 2, 4, 8, :m  #      } n[2][4][8], m;
  }                     #  };
end
```

最初の引数にブロックではなく、型情報としてのオブジェクトを与えることも出来ます。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeA = struct {
    int :a
  }

  TypeC = struct {                 #  struct TypeC {
    struct TypeA, :n, 2, 4, 8, :m  #      struct TypeA n[2][4][8], m;
  }                                #  };
end
```

無名構造体の場合、引数は渡さずにブロックを渡すだけです。

``` ruby:ruby
module MyModule
  extend Gogyou

  TypeD = struct {  #  struct TypeD {
    struct {        #      struct {
      int :a, :b    #          int a, b;
    }               #      };
  }                 # };
end
```

struct 内の struct の呼び出し方法を示します。union も同様に利用できます。

  * `struct { ... } -> nil`
  * `struct proc_object, field_name, *array_elements`
  * `struct user_type_info, field_name, *array_elements`

  * `union { ... } -> nil`
  * `union proc_object, field_name, *array_elements`
  * `union user_type_info, field_name, *array_elements`

引数なしのブロック付きで呼ぶと、無名構造体 (union であれば無名共用体) を定義します。

`proc_object` を与えて呼ぶことで、続く `field_name` によってその内部を参照することが出来ます。

`array_elements` は任意個の整数値で、直前のフィールド名を配列として定義します。

`field_name` と `array_elements` を組にして複数個並べることが出来ます。

`user_type_info` は、任意のオブジェクト (クラスやオブジェクトを含む) を型として用いる場合に利用できます。
詳細は『About user typed info』を見て下さい。


## About user typed info (利用者定義の型情報について)

構造体・共用体の内部フィールドには、利用者が定義した型情報を用いることが出来ます。

この型情報は次のメソッドを持ったあらゆるオブジェクト (クラスでもモジュールでも、インスタンスでも構いません) のことです。

  * `.bytesize`
  * `.bytealign`
  * `.extensible?`
  * `.aref(buffer, offset)`
  * `.aset(buffer, offset, data)`

例として、MD5 を定義する場合の型情報は次のようになります。

``` ruby:ruby
class MD5
  def self.bytesize
    16
  end

  def self.bytealign
    1
  end

  def self.extensible?
    false
  end

  def self.aref(buffer, offset)
    _ _ _ SNIP _ _ _
  end

  def self.aset(buffer, offset, data)
    _ _ _ SNIP _ _ _
  end
end
```

これらのメソッドを一つ一つ定義する代わりに、任意のクラス・モジュールの中で ``Gogyou.define_typeinfo`` を用いることでまとめて定義することも出来ます。

``` ruby:ruby
class MD5
  Gogyou.define_typeinfo(
    self,
    16,    # bytesize
    1,     # bytealign
    false, # extensible?
    ->(buffer, offset) { _ _ _ SNIP _ _ _ },       # aref
    ->(buffer, offset, data) { _ _ _ SNIP _ _ _ }) # aset
end
```

順を追って説明していきます。

### ``.bytesize``

このメソッドはその型が必要とする領域のバイト数を正の整数値で返します。

型が拡張構造になっている場合は、最小値となる値を返します。

MD5 を定義する場合、16バイトなので ``16`` を返します。

### ``.bytealign``

このメソッドはその型のアライメントサイズを正の整数値で返します。

MD5 を定義する場合、内部表現は1バイトの塊なので ``1`` を返します
(MD5 の実装によっては ``4`` だったり ``8`` だったり、はたまた ``16`` になるかもしれません)。

### ``.extensible?``

このメソッドはその型が常に固定長か、任意に拡張する構造になっているかどうかを返します。

``true`` であれば拡張構造であることを意味し、``false`` であれば固定長であることを意味します。

MD5 は固定長なので、``false`` を返します。

### ``.aref(buffer, offset)``

このメソッドは構造体のフィールドを参照した場合に呼ばれます。

``buffer`` はバイナリデータとしての String インスタンスです (※gogyou-0.2.4 からは Fiddle::Pointer や FFI::AbstractMemory インスタンスである可能性もあります)。

``offset`` はバッファ上における、フィールドの絶対位置をバイト値で表した整数値です。

戻り値はその構造体のフィールドに対するインスタンスを返します。

MD5 の場合、``buffer`` を元にした MD5 のインスタンスを返すべきです。

``` ruby:ruby
class MD5
  def self.aref(buffer, offset)
    new(buffer.byteslice(offset, 16))
  end
end
```

もしもインスタンスの変更を反映させる ``MD5#[]=`` のようなメソッドが必要であるならば、上述したメソッドではうまく行きません。
理由は ``buffer.byteslice`` によって ``buffer`` オブジェクトが切り離されてしまっているからです。

クラスを MD5 のデータが保持されるだけの構造から、``buffer`` と ``offset`` を保持する構造に変更する必要があります。
その上でメソッドの定義を変更します。

``` ruby:ruby
class MD5
  def self.aref(buffer, offset)
    new(buffer, offset)
  end

  def [](index)
    raise IndexError unless index >= 0 && index < 16
    @buffer.getbyte(@offset + index)
  end

  def []=(index, num)
    raise IndexError unless index >= 0 && index < 16
    @buffer.setbyte(@offset + index, num)
  end
end
```

### ``.aset(buffer, offset, data)``

このメソッドは構造体のフィールドへデータを代入した時に呼ばれます。

例えば、`structobj.field = data` のような場合です。

``buffer`` はバイナリデータとしての String インスタンスです (※gogyou-0.2.4 からは他のライブラリが提供するポインタオブジェクトである可能性もあります)。

``offset`` はバッファ上における、フィールドの絶対位置をバイト値で表した整数値です。

``data`` は代入する値です。

戻り値は無視されます。

``data`` に対してどのような値 (オブジェクト) を受け入れるのかを決定するのは、型情報を定義する側の問題となります。

MD5 の場合、最低でも MD5 インスタンスを受け入れるようにするべきです。

今回は MD5 インスタンスだけではなく 16バイトの文字列、そして ``nil`` を受け取れるようにしてみます。

``` ruby:ruby
class MD5
  def self.aset(buffer, offset, data)
    case data
    when MD5
      buffer.setbinary(offset, data.to_binary)
    when String
      buffer.setbinary(offset, data.byteslice(0, 16))
    when nil
      buffer.setbinary(offset, ?0 * 16)
    else
      raise ArgumentError, "data is not a MD5, String or nil"
    end
  end
end
```

## Define packed struct

GCC の ``__attribute__((packed))`` に似たパックされた構造体のフィールドを定義するには、そのフィールドを ``packed`` メソッドのブロックとして囲うことで行います。

構造体自体をパックするには、その構造体のフィールド全体を ``packed`` することで行います。

また、``packed`` の中に ``struct`` や ``union`` を含めることも出来、その入れ子内部で ``packed`` を行うことも出来ます。

ただし ``packed`` を直接入れ子にして呼び出すことは出来ません。

構造体全体を ``packed`` する場合:

``` ruby:ruby
X = Gogyou.struct {
  packed {
    char :a
    int :b
    int :c
  }
}

p X.bytesize # => 9
```

``packed`` された入れ子構造体の内部でさらに ``packed`` する場合:

``` ruby:ruby
Y = Gogyou.struct {
  char :a
  packed {
    struct {
      int :b
    }
  }
  char :c, 3
  int :d
}

p Y.bytesize # => 12
```

直接入れ子にして ``packed`` して例外が発生する場合:

``` ruby:ruby
Z = Gogyou.struct {
  packed {
    packed {  ## => EXCEPTION!
      char :a
      int :b
    }
  }
}
```


## Use Fiddle::Pointer or FFI::AbstractMemory as buffer object of struct (構造体のバッファオブジェクトとして Fiddle::Pointer や FFI::AbstractMemory を使う)

構造体の実体となるバッファオブジェクトは、文字列だけではなく Fiddle::Pointer や FFI::AbstractMemory インスタンスを指定することも出来ます (gogyou-0.2.4 にて追加)。

Fiddle::Pointer を利用する場合は、"gogyou/fiddle" を ``require`` する必要があります。
この時 ``require "fiddle"`` されていなければ "gogyou/fiddle" の内部で ``require`` されます。

あとは作成した構造体に ``bind`` する時、任意の Fiddle::Pointer インスタンスを指定します。

``` ruby:ruby
require "gogyou/fiddle"

ptr = Fiddle::Pointer.malloc(YourStruct.bytesize)
data = YourStruct.bind(ptr)
```

同様に FFI::AbstractMemory (または派生クラス) を利用する場合は、"gogyou/ffi" を ``require`` する必要があります。
この時 ``require "ffi"`` されていなければ "gogyou/ffi" の内部で ``require`` されます。

あとは作成した構造体に ``bind`` する時、任意の FFI::AbstractMemory (または派生クラス) インスタンスを指定します。

``` ruby:ruby
require "gogyou/ffi"

ptr = FFI::MemoryPointer.new(YourStruct.bytesize)
data = YourStruct.bind(ptr)
```


## Demerit (短所)

  * Can't be handled pointer
    (ポインタが扱えない)

  * The cost is high for reference/asignment from/to fields
    (フィールドに対する参照・代入のコストが高い)


## Available typenames when definision struct (構造体定義の際に利用できる型名)

  * C の型名

                                符号あり    符号なし
                                ----        ----
        char 型                 char        uchar
                                            unsigned_char
        short 型                short       ushort
                                            unsigned_short
        int 型                  int         uint
                                            unsigned_int
        long 型                 long        ulong
                                            unsigned_long
        long long 型            longlong    ulonglong
                                long_long   unsigned_long_long
        sizeof 型               ssize_t     size_t
        ポインタ整数型          intptr_t    uintptr_t
        float                   float       N/A
        double                  double      N/A

  * バイトオーダー環境依存・ビット数環境非依存

                                  バイトオーダー環境依存  バイトオーダー反転
                                  符号あり    符号なし    符号あり      符号なし
                                  ----        ----        ----          ----
        8ビット整数型             int8_t      uint8_t     N/A           N/A
        16ビット整数型            int16_t     uint16_t    int16_swap    uint16_swap
        32ビット整数型            int32_t     uint32_t    int32_swap    uint32_swap
        64ビット整数型            int64_t     uint64_t    int64_swap    uint64_swap
        16ビット浮動小数点実数型  float16_t   N/A         float16_swap  N/A
        32ビット浮動小数点実数型  float32_t   N/A         float32_swap  N/A
        64ビット浮動小数点実数型  float64_t   N/A         float64_swap  N/A

  * バイトオーダー・ビット数環境非依存

                                  ビッグエンディアン      リトルエンディアン
                                  符号あり    符号なし    符号あり      符号なし
                                  ----        ----        ----          ----
        16ビット整数型            int16_be    uint16_be   int16_le      uint16_le
        24ビット整数型            int24_be    uint24_be   int24_le      uint24_le
        32ビット整数型            int32_be    uint32_be   int32_le      uint32_le
        48ビット整数型            int48_be    uint48_be   int48_le      uint48_le
        64ビット整数型            int64_be    uint64_be   int64_le      uint64_le
        16ビット浮動小数点実数型  float16_be  N/A         float16_le    N/A
        32ビット浮動小数点実数型  float32_be  N/A         float32_le    N/A
        64ビット浮動小数点実数型  float64_be  N/A         float64_le    N/A
