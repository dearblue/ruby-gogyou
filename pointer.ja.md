
# About pointer (ポインタについて) (***EXPERIMENTAL FEATURE***)

非常に限定的ながらポインタを扱うことが出来るようになりました (0.2.5 にて追加)。

構造体を作成する時に、ポインタとしたい要素を配列としてくくることで定義できます。

C と ruby を並べて記述しています (左側が ruby、右側が C):

``` ruby:ruby
int [:a]        # => int *a

int [[[[:a]]]]  # => int ****a

int [:a, 4]     # =>     (NOW) int (*a)[4]
                #    (FEATURE) int *a[4]      : "a" is a 4 elements pointer of int

int [:a], 4     # =>     (NOW) int *a[4]
                #    (FEATURE) int (*a)[4]    : "a" is a pointer of 4 elements int

int [:a, 4], 8  # =>     (NOW) int (*a[8])[4]
                #    (FEATURE) int (*a[4])[8] : "a" is a 4 elements pointer of 8 elements int

const int [:a]  # =>     (NOW) int *const a
                #    (FEATURE) const int *a   : "a" is a pointer of constant int

int [const(:a)] # =>     (NOW) NOT WORK
                #    (FEATURE) int *const a   : "a" is a constant pointer of int

a[]             # => *a , a[0]
a[1]            # => a[1]
a[][1]          # => (*a)[1] , a[0][1]
```

実際に利用した例 (***ruby の規律から逸脱しているため、実用しないで下さい***):

``` ruby:ruby
X = Gogyou.struct {
  int [:a]
}

frozen_str = "abcdefghijklmn"
x = X.new([frozen_str].pack("p"))
frozen_str.freeze

x.a[] = 0x44434241      # *x.a = 0x44434241
p frozen_str            # => "ABCDefghijklmn"
                        #     ^^^^

x.a[2] ^= 0x20202020    # same as C code
p frozen_str            # => "ABCDefghIJKLmn"
                        #             ^^^^

x.a += 1                # address + sizeof(int[1])
x.a[] = 0x24232221      # *x.a = 0x24232221
p frozen_str            # => "ABCD!\"\#$IJKLmn"
                        #         ^^^^^^
```

実験的な機能のため、以下の制限(出来無いこと)があります:

  * const 修飾子が機能しない (又は挙動がおかしい)
  * typedef 出来ない
  * ポインタと配列の定義を混ぜると挙動がおかしい
  * そもそも C に見えない!


## 自己参照構造体、相互参照構造体について

ポインタによる自己参照構造体、相互参照構造体を定義する場合、Gogyou::Struct クラスを継承したクラスを定義することで可能です。

``` C:C
struct TypeA;

struct TypeB
{
    struct TypeA *a;
    struct TypeB *b;
};

struct TypeA
{
    struct TypeB *b;
};
```

``` ruby:ruby
class TypeA < Gogyou::Struct
  # class definition only!
end

class TypeB < Gogyou::Struct
  struct {
    struct TypeA, [:a]
    struct TypeB, [:b]
  }
end

class TypeA
  struct {
    struct TypeB, [:b]
  }
end
```
