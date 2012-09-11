#vim: set fileencoding:utf-8

# gogyou.rb
# - AUTHOR: dearblue <dearblue@sourceforge.jp>
# - WEBSIZE: http://sourceforge.jp/projects/rutsubo/
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

# gogyou は ruby 向けに作成され、バイナリデータと構造体との変換を容易にするためのライブラリです。名前は春の七種の一つ『ごぎょう』からとりました。
#
# ruby に組み込まれている String#unpack / Array#pack は Struct クラスとの関係性はまったくありません。対応付けをするのも自力で書く必要があり、パックフォーマットと変数の関係性の直接的な結びつきがないため視認性に乏しいと言わざるをえません。
#
# gogyou ライブラリはこの負担を軽減することとともに、視認性の向上を目的に作成されました。
#
# ただし、rdoc の適用対象とは (やっぱり) なりません。必要であれば定数定義の前にコメントを入力するか、サブクラスを定義してそこで rdoc を記述するのがいいでしょう。
#
# == 基本
#
# gogyou ライブラリを用いることによって以下のように記述できます。
#
#   require "gogyou"
#
#   Sample = Gogyou.struct do
#       uint32_t :data1     # C の uint32_t (32ビット無符号整数値) を定義
#       int16_t  :data2, 2  # C の int16_t (16ビット符号付き整数値) を要素数 2 で定義
#       uint64_t :data3     # C の uint64_t (64ビット無符号整数値) を定義
#       uint8_t  :data4, 2  # C の uint8_t (8ビット無符号整数値) を要素数 2 で定義
#       char     :data5, 2  # C の char (8ビット符号付き整数値) を要素数 2 で定義
#       ustring  :data6, 4  # NULL 終端の UTF-8 文字列を定義 / 文字列長は 4 / 要素数 1
#       binary   :data7, 8  # ASCII-8BIT 文字列を定義 / 文字列長は 8 / 要素数 1
#   end
#
#   p Sample::PACK_FORMAT # => "I s2 Q C2 c2 Z4 a8" # 実際には空白は含まれません
#   p Sample::SIZE # => 32
#
# Sample クラスは Struct クラスのインスタンス (ruby から見ればクラスオブジェクト) で、PACK_FORMAT、SIZE の定数が定義され、.unpack / .pack メソッドが定義されます。
#
# つまり上記の例であれば、
#
#   sample = Sample.unpack(data_sequence)
#   data_sequence = sample_data.pack
#
# というようなメソッド呼び出しができる Sample クラスが定義されることになります。
#
# == Gogyou.struct ブロック内は self コンテキストが切り替わる
#
# Gogyou.struct を呼び出すときに渡すブロックは、そのブロック内での self コンテキストが切り替わります。
#
# ブロックの外で呼び出せるメソッドがブロック内で呼び出せないもしくは意図しない結果になる場合は、このことが原因と見ると対策しやすいかもしれません。
#
# こんな (一見横暴な) 仕様になっているのは、ブロックパラメータの受け取りと型名を記述する際の変数の記述という煩わしさから開放するという目的を達成させるためです。
#
# 実装としては Gogyou.struct メソッド内で instance_eval にブロックをそのまま渡しています。
#
# == 各要素は境界上に配置される
#
# それぞれの要素のバイトオフセットは C 言語の構造体に倣って、各要素の境界上に配置されます。
#
#   Sample = Gogyou.struct do
#       uint8_t  :data1 # 0000h に配置。幅は1。
#       uint16_t :data2 # 0002h に配置。幅は2。
#       uint8_t  :data3 # 0004h に配置。幅は1。
#       uint32_t :data3 # 0008h に配置。幅は4。
#       uint64_t :data3 # 0010h に配置。幅は8。
#   end
#
#   p Sample::PACK_FORMAT # => "C x S C x3 L x4 Q"
#
# == 入れ子になった構造体
#
# 入れ子の構造体表記も可能です。入れ子の入れ子のさらに・・・みたいなやつも記述可能ですが、展開がその分遅くなります。
#
#   Sample = Gogyou.struct do
#       struct :ref1 do     # 入れ子の構造体。名無しクラス (Struct を祖に持つクラス) を返します。
#           uint32_t :data1 # ref1.data1 で参照できます。
#           uint32_t :data2
#       end
#
#       int :data3
#   end
#
#   p Sample::PACK_FORMAT # => "a8 i"
#
# == エンディアン指定
#
# エンディアン指定も可能です。サフィックスが『_t』で終わるやつは基本的に『_le』でリトルエンディアン、『_be』かサフィックスなしでビッグエンディアンになります。
#
#   Sample = Gogyou.struct do
#       uint32_t :data1  # 動作環境に依存。
#       uint32 :data2    # 常にビッグエンディアン (ネットワークエンディアン) / パックフォーマットでは『N』と同等。
#       uint32_be :data3 # uint32 と同じ。
#       uint32_le :data4 # 常にリトルエンディアン (バックスエンディアン) / パックフォーマットでは『V』と同等。
#   end
#
#   p Sample::PACK_FORMAT # => "L N N V" # 実際は環境によって変わってきます
#
# == 境界上に配置されない要素
#
# 型名の後ろに感嘆符『!』をつけるとその型の境界上に配置されるのを抑制します。GCC でいうところの "__attribute__((__packed__))" が付いている構造体です。
#
#   Sample = Gogyou.struct do
#       uint8_t!  :data1, 3 # 0000h に配置。幅は1。
#       uint16_t! :data2, 3 # 0003h に配置。幅は2。
#       uint32_t! :data3, 3 # 0009h に配置。幅は4。
#   end
#
#   p Sample::PACK_FORMAT # => "C3 S3 L3"
#   p Sample::SIZE # => 21
#
# == 境界指定
#
# "alignment" (短縮して "align" も利用可) で、次の要素の配置が指定境界に来るようになります。ただし要素自体の境界配置が無効化さるわけではないため、そのことも含めて強制させるためには『!』を用いる必要があります。
#
#   Sample = Gogyou.struct do
#       uint8_t :data1  # 0000h に配置。
#       alignment 16    # 穴埋め。次の要素は0010hに配置される。
#       uint32_t :data2 # 0010h に配置。
#   end
#
#   p Sample::PACK_FORMAT # => "C x15 L"
#
# == 任意幅の穴埋め
#
# "padding" で、任意幅の穴埋めができます。
#
#   Sample = Gogyou.struct do
#       uint8_t :data1  # 0000h に配置。
#       padding 8       # 穴埋め。次の要素は 0009h に配置される。
#       uint32_t :data2 # 4バイト境界上の 000Ch に配置。
#   end
#
#   p Sample::PACK_FORMAT # => "C x8 x3 L"
#
# == 型の別名定義
#
# "typedef" で、C でいう型の別名が定義できます。
#
#   Sample = Gogyou.struct do
#       typedef :uint, :HANDLE # 以降 HANDLE を使うと uint を指定したことになる
#
#       uint8_t :data1, 3
#       HANDLE :data2
#   end
#
#   p Sample::PACK_FORMAT # => "C3 x I"
#
# 入れ子定義内でも親で定義した typedef は有効です。
#
#   Sample = Gogyou.struct do
#       typedef :uint, :HANDLE
#
#       HANDLE :data1
#       struct :dataset do
#           HANDLE :data1   # この HANDLE は親スコープで typedef したものが継承されたものです。
#           HANDLE :data2
#       end
#   end
#
# また任意のクラスを指定することで外部クラスをブロック内で定義することができるようになります。
#
#   Sample = Gogyou.struct do
#       typedef MD5 :MD5 # 以降 MD5 で MD5 クラスが展開と格納を行う
#
#       MD5 :md5
#   end
#
# この MD5 クラス (モジュールでも可) は、pack / unpack メソッドを持ち、SIZE 定数 (バイト数。MD5 なので 16) を持つ必要があります。
#
#   class MD5
#       SIZE = 16
#
#       def self.pack(obj)
#           ...
#           # string オブジェクトを返さなければならない
#           # bytesize は SIZE と等しくなければならない
#       end
#
#       def self.unpack(str)
#           # str は SIZE 定数で指定した分量のバイナリ文字列
#           ...
#           # 展開したオブジェクトを返す
#       end
#   end
#
# == 型名一覧
#
# それぞれ正規表現に沿った見方をしてください。。。ちょーみづれー
#
# - バイナリ列: binary
# - UTF-8 文字列: ustring
# - 整数 (環境依存 : ビット数、エンディアン): u?char, u?short!?, u?int!?, u?long!?, u?longlong!?
# - 整数 (環境依存 : ビット数、エンディアン): s?size_t!?, u?intptr_t!?
# - 整数 (環境依存 : エンディアン): u?int16_t!?, u?int32_t!?, u?int64_t!?
# - 浮動少数 (環境依存 : ビット数、エンディアン): float!?, double!?
# - 浮動少数 (環境非依存): float(_be|_le)!?, double(_be|_le)!?
# - 整数 (環境非依存): u?int8(_t)?, u?int16(_be|_le)?!?, u?int32(_be|_le)?!?, u?int64(_be|_le)?!?
#
# == 実行速度面では不利
#
# 構造体定義は結構重い処理 (数ミリ秒) になっています。しかし、アプリケーション初期化時において各構造体ごとに一度だけ処理されるため、気になることはあまりないと思います。
#
# そしてやはり pack / unpack は自力で記述した場合と比べれば重くなりますが、記述の容易さ・可読性に免じて目を瞑ってください。

module Gogyou
    Gogyou = self

    # このメソッドにブロックつきで呼び出すことによって、Struct の構築と、Array#pack および String#unpack を用いてデータの詰め込みと展開を行える機能を持ったクラスを構築することができます。
    #
    # 詳しい説明は Gogyou モジュールに記述してあります。
    def self.struct(&block)
        farm = StructFarm.new
        farm.instance_eval(&block)
        define_struct(farm)
    end

    # Gogyou.struct によって生成したクラスが extend によって組み込むモジュールです。
    #
    # 利用者定義クラスのクラスメソッドとして利用されます。
    module ModuleUnpacker
        def unpack(str)
            ary = str.unpack(self::PACK_FORMAT)
            self::PROPERTIES.each_with_index do |(name, size, offset, pack, unpack), i|
                unless offset
                    # メンバ変数の宣言のみ
                    ary.insert(i, nil)
                    next
                end

                if size && size > 1
                    ary[i] = ary.slice(i, size)
                    ary.slice!(i + 1, size - 1)
                end

                if unpack
                    if size > 1
                        a = ary[i]
                        size.times do |j|
                            a[j] = unpack.(a[j])
                        end
                    else
                        ary[i] = unpack.(ary[i])
                    end
                end
            end
            new(*ary)
        end
    end

    # Gogyou.struct によって生成したクラスが extend によって組み込むモジュールです。
    #
    # 利用者定義クラスのクラスメソッドとして利用されます。
    module ModulePacker
        def pack(obj)
            obj = obj.each
            ary = []
            self::PROPERTIES.each do |name, size, offset, pack, unpack|
#p [name, size, offset, pack, unpack]
                unless offset
                    # メンバ変数の宣言のみ
                    obj.next
                    next
                end

                if pack
                    if size > 1
                        obj.next.each do |a|
                            ary << pack.call(a)
                        end
                    else
                        ary << pack.call(obj.next)
                    end
                else
                    if size > 1
                        ary.concat obj.next
                    else
                        ary << obj.next
                    end
                end
#p ary
            end

            ary.pack(self::PACK_FORMAT)
        end
    end

    # Gogyou.struct によって生成したクラスが include によって組み込むモジュールです。
    #
    # 利用者定義クラスのインスタンスメソッドとして利用されます。
    module Packer
        def pack
            self.class.pack(self)
        end
    end

    module Types
        SIZEOF_CHAR     = [0].pack("C").bytesize
        SIZEOF_SHORT    = [0].pack("S").bytesize
        SIZEOF_INT      = [0].pack("I").bytesize
        SIZEOF_LONG     = [0].pack("L").bytesize
        SIZEOF_LONGLONG = [0].pack("Q").bytesize
        SIZEOF_SIZE_T   = [nil].pack("P").bytesize
        SIZEOF_FLOAT    = [0].pack("F").bytesize
        SIZEOF_DOUBLE   = [0].pack("D").bytesize

        FORMATOF_INT8_T  = "c"
        FORMATOF_UINT8_T = "C"

        FORMATOF_INT16_T   = "s"
        FORMATOF_INT16_BE  = FORMATOF_INT16_T + ">"
        FORMATOF_INT16_LE  = FORMATOF_INT16_T + "<"
        FORMATOF_UINT16_T  = "S"
        FORMATOF_UINT16_BE = FORMATOF_UINT16_T + ">"
        FORMATOF_UINT16_LE = FORMATOF_UINT16_T + "<"

        case
        when SIZEOF_LONG == 4
            FORMATOF_INT32_T = "l"
            FORMATOF_UINT32_T = "L"
        when SIZEOF_INT == 4
            FORMATOF_INT32_T = "i"
            FORMATOF_UINT32_T = "I"
        else
            raise "can not be define int32_t type"
        end

        FORMATOF_INT32_BE = FORMATOF_INT32_T + ">"
        FORMATOF_INT32_LE = FORMATOF_INT32_T + "<"
        FORMATOF_UINT32_BE = FORMATOF_UINT32_T + ">"
        FORMATOF_UINT32_LE = FORMATOF_UINT32_T + "<"

        case
        when SIZEOF_LONG == 8
            FORMATOF_INT64_T = "l"
            FORMATOF_UINT64_T = "L"
        when SIZEOF_LONGLONG == 8
            FORMATOF_INT64_T = "q"
            FORMATOF_UINT64_T = "Q"
        else
            raise "can not be define int64_t type"
        end

        FORMATOF_INT64_BE = FORMATOF_INT64_T + ">"
        FORMATOF_INT64_LE = FORMATOF_INT64_T + "<"
        FORMATOF_UINT64_BE = FORMATOF_UINT64_T + ">"
        FORMATOF_UINT64_LE = FORMATOF_UINT64_T + "<"

        case
        when SIZEOF_SIZE_T == 4
            FORMATOF_SSIZE_T = FORMATOF_INT32_T
            FORMATOF_SIZE_T = FORMATOF_UINT32_T
        when SIZEOF_SIZE_T == 8
            FORMATOF_SSIZE_T = FORMATOF_INT64_T
            FORMATOF_SIZE_T = FORMATOF_UINT64_T
        else
            raise "can not be define size_t type"
        end

        FORMATOF_INTPTR_T = FORMATOF_SSIZE_T
        FORMATOF_UINTPTR_T = FORMATOF_SIZE_T
        SIZEOF_INTPTR_T = SIZEOF_UINTPTR_T = SIZEOF_SIZE_T
    end

    if false
        Types.constants.sort.each do |e|
            puts "#{e}: #{Types.const_get(e).inspect}."
        end
        raise "TEST BREAK!"
    end

    class Property < Struct.new(:name, :elementof, :offset, :pack, :unpack)
        BasicStruct = superclass
    end

    # 構造体クラスの定義作業に使われるクラスです。
    #
    # Gogyou.struct に渡すブロック内において self はこのクラスのインスタンスに切り替わるため、レシーバなしのメソッド呼び出しはこのクラスのインスタンスメソッドが呼ばれることになります。
    #
    # もしブロック外では問題ないのにブロック内で問題が出る場合、このことが原因になることがあります。
    class StructFarm < Struct.new(:packlist,
                                  :properties,
                                  :offset)

        # Gogyou::StructFarm の派生元クラスとなる Struct インスタントクラス。
        BasicStruct = superclass

        include Types

        def initialize
            super([], [], 0)
        end

        def initialize_clone(obj)
            self.packlist = []
            self.properties = []
            self.offset = 0
        end

        def variable?
            false
        end

        def union(name, size = 1, &block)
            raise NotImplementedError
            f = UnionFarm.new
        end

        def struct(name, elementof = 1, &block)
            f = clone
            f.instance_eval(&block)
            type = Gogyou.instance_eval { define_struct(f) }

            name = name.to_sym
            elementof = _convert_size(elementof)
            elementof.times { packlist << "a#{type::SIZE}" }
            properties << [name, elementof, offset, type.method(:pack), type.method(:unpack)]
            self.offset += type::SIZE * elementof
            type
        end

        def voidp(name, size = 1)
            define(name, "P", 1, size, SIZEOF_SIZE_T, nil)
        end

        def typedef(target, aliasname)
            case target
            when String, Symbol
                singleton_class.class_eval do
                    alias_method aliasname, target
                    alias_method :"#{aliasname}!", :"#{target}!" unless aliasname =~ /!$/ || target =~ /!$/
                end
            when Class
                sizeof = target.const_get(:SIZE)
                pack = target.method(:pack)
                unpack = target.method(:unpack)
                usertype(aliasname, sizeof, pack, unpack)
            else
                sizeof = target.size
                pack = target.method(:pack)
                unpack = target.method(:unpack)
                usertype(aliasname, sizeof, pack, unpack)
            end
            self
        end

        # [tipename (require)]
        #       型名
        # [sizeof (require)]
        #       1要素あたりのオクテット数
        # [pack (optional)]
        #       格納する場合に呼び出されるメソッド。不要であれば nil を指定可。
        # [unpack (optional)]
        #       展開する場合に呼び出されるメソッド。不要であれば nil を指定可。
        def usertype(typename, sizeof, pack = nil, unpack = nil)
            #raise(ArgumentError, "need block") unless reduce
            #typename = typename.to_sym
            #raise(ArgumentError, "wrong typename (#{typename})") if typename =~ /\s/m || typename !~ /^[_\w][_\w\d]*$/
            define_singleton_method(typename, &->(name, size = 1) {
                name = name.to_sym
                size = _convert_size(size)
                packlist.concat(["a#{sizeof}"] * size)
                properties << [name, size, offset, pack, unpack]
                self.offset += sizeof * size
                self
            })
            self
        end

        def padding(size)
            size = _convert_size(size)
            packlist << (size > 1 ? "x#{size}" : "x")
            self.offset += size
            self
        end

        def alignment(elementof)
            elementof = _convert_size(elementof)
            size = (elementof - offset % elementof) % elementof
            padding(size) if size > 0
            self
        end

        alias align alignment

        # call-seq:
        # exclude(name, ...)
        #
        # 追加するメンバ変数を定義します。これで追加されたメンバ変数は pack / unpack の対象外として扱われます。
        #
        # インスタンス変数の代わりに定義することを想定しています。
        def exclude(*names)
            names.each do |n|
                property = [n.to_sym, nil, nil]
                properties << property
            end
            self
        end

        # メンバ変数宣言の実体。int や long などの型指定時に呼び出されます。
        #
        # [name]        アクセッサ名 (メンバ名)
        # [format]      パックフォーマット (Array#pack や String#unpack を参照)
        # [elementof]   要素数
        # [sizeof]      1要素あたりのオクテット数
        # [elements]    パックフォーマットの要素数が複数要素として展開される場合は nil を指定する
        # [pack]        Array#pack の時に置き換える場合の前処理
        # [unpack]      String#unpack の時に置き換える後処理
        def define(name, format, elementof, sizeof, elements = nil, packer = nil, unpacker = nil)
            name = name.to_sym
            elementof = _convert_size(elementof)
            packlist << "#{format}#{elementof > 1 ? elementof : nil}"
            property = [name, elements || elementof, offset]
            property << packer << unpacker if packer || unpacker
            properties << property
            self.offset += sizeof * elementof
            self
        end

        def unpack_ustring(str)
            str.force_encoding(Encoding::UTF_8)
        end

        def pack_ustring(str)
            str
        end

        [
            # 0: type name
            # 1: size of type
            # 2: number of multiple elements
            # 3: default number of element for pack format
            # 4.0: pack format (non-suffix)
            # 4.1: pack format ("_be" suffixed)
            # 4.2: pack format ("_le" suffixed)
            # 4.3: pack format ("_t" suffixed)
            # 5: pack method (optional)
            # 6: unpack method (optional)
            [:binary,    1, 1,   false, ["a", nil, nil, nil]],
            [:ustring,   1, 1,   false, ["Z", nil, nil, nil], :pack_ustring, :unpack_ustring],
            [:char,      SIZEOF_CHAR,     nil, true,  ["c", nil, nil, nil]],
            [:uchar,     SIZEOF_CHAR,     nil, true,  ["C", nil, nil, nil]],
            [:short,     SIZEOF_SHORT,    nil, true,  ["s", nil, nil, nil]],
            [:ushort,    SIZEOF_SHORT,    nil, true,  ["S", nil, nil, nil]],
            [:int,       SIZEOF_INT,      nil, true,  ["i", nil, nil, nil]],
            [:uint,      SIZEOF_INT,      nil, true,  ["I", nil, nil, nil]],
            [:long,      SIZEOF_LONG,     nil, true,  ["l", nil, nil, nil]],
            [:ulong,     SIZEOF_LONG,     nil, true,  ["L", nil, nil, nil]],
            [:longlong,  SIZEOF_LONGLONG, nil, true,  ["q", nil, nil, nil]],
            [:ulonglong, SIZEOF_LONGLONG, nil, true,  ["Q", nil, nil, nil]],
            [:float,     SIZEOF_FLOAT,    nil, true,  ["F", "g", "e", nil]],
            [:double,    SIZEOF_DOUBLE,   nil, true,  ["D", "G", "E", nil]],
            [:size_t,    SIZEOF_SIZE_T,   nil, true,  [FORMATOF_SIZE_T,    nil, nil, nil]],
            [:ssize_t,   SIZEOF_SIZE_T,   nil, true,  [FORMATOF_SSIZE_T,   nil, nil, nil]],
            [:intptr_t,  SIZEOF_INTPTR_T, nil, true,  [FORMATOF_INTPTR_T,  nil, nil, nil]],
            [:uintptr_t, SIZEOF_INTPTR_T, nil, true,  [FORMATOF_UINTPTR_T, nil, nil, nil]],
            [:int8,      1, nil, true, [FORMATOF_INT8_T,    nil, nil, FORMATOF_INT8_T]],
            [:uint8,     1, nil, true, [FORMATOF_UINT8_T,   nil, nil, FORMATOF_UINT8_T]],
            [:int16,     2, nil, true, [FORMATOF_INT16_BE,  FORMATOF_INT16_BE,  FORMATOF_INT16_LE,  FORMATOF_INT16_T]],
            [:uint16,    2, nil, true, [FORMATOF_UINT16_BE, FORMATOF_UINT16_BE, FORMATOF_UINT16_LE, FORMATOF_UINT16_T]],
            [:int32,     4, nil, true, [FORMATOF_INT32_BE,  FORMATOF_INT32_BE,  FORMATOF_INT32_LE,  FORMATOF_INT32_T]],
            [:uint32,    4, nil, true, [FORMATOF_UINT32_BE, FORMATOF_UINT32_BE, FORMATOF_UINT32_LE, FORMATOF_UINT32_T]],
            [:int64,     8, nil, true, [FORMATOF_INT64_BE,  FORMATOF_INT64_BE,  FORMATOF_INT64_LE,  FORMATOF_INT64_T]],
            [:uint64,    8, nil, true, [FORMATOF_UINT64_BE, FORMATOF_UINT64_BE, FORMATOF_UINT64_LE, FORMATOF_UINT64_T]],
        ].each do |name, sizeof, ismultielement, defaultelements, format, pack, unpack|
            default_elementnum = defaultelements ? " = 1" : ""
            ["", "_be", "_le", "_t"].zip(format).each do |suffix, f|
                next unless f

                if pack || unpack
                    reduce = ""
                    reduce << ", " << (pack ? "method(#{pack.to_sym.inspect})" : "nil")
                    reduce << ", " << (unpack ? "method(#{unpack.to_sym.inspect})" : "nil")
                end

                class_eval(x = <<-EOS, "#{__FILE__}<#{name}#{suffix}>", __LINE__ + 1)
                    def #{name}#{suffix}(name, elementnum#{default_elementnum})
                        alignment #{sizeof}
                        define(name, #{f.inspect}, elementnum, #{sizeof}, #{ismultielement.inspect}#{reduce})
                    end

                    def #{name}#{suffix}!(name, elementnum#{default_elementnum})
                        define(name, #{f.inspect}, elementnum, #{sizeof}, #{ismultielement.inspect}#{reduce})
                    end
                EOS
#puts x.gsub!(/\s+/m, " ").strip
            end
        end

#p instance_methods.sort - Object.methods

        def _convert_size(size)
            size = size.to_i
            raise ArgumentError, "size is must not zero or negative" unless size > 0
            size
        end
    end

    class << self
        private
        def define_struct(farm)
            syms = farm.properties.map { |e| e[0].to_sym }
            raise(ArgumentError, "not defined struct members") if syms.empty?
            type0 = ::Struct.new(*syms)
            type0.class_eval do
                const_set(:PACK_FORMAT, farm.packlist.join("").freeze)
                const_set(:SIZE, farm.offset)
                const_set(:VARIABLE, farm.variable?)
                const_set(:PROPERTIES, farm.properties.freeze)
                extend ModuleUnpacker
                extend ModulePacker
                include Packer
            end
            type = Class.new(type0)
            type.const_set(:BasicStruct, type0)
            type
        end
    end
end
