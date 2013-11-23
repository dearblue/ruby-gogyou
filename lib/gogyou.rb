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

    def alloc
      unpack(?\0 * self::SIZE)
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
    # [sizeof]      1要素あたりのバイト数
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
      [:unsigned_char,     SIZEOF_CHAR,     nil, true,  ["C", nil, nil, nil]],
      [:short,     SIZEOF_SHORT,    nil, true,  ["s", nil, nil, nil]],
      [:ushort,    SIZEOF_SHORT,    nil, true,  ["S", nil, nil, nil]],
      [:unsigned_short,    SIZEOF_SHORT,    nil, true,  ["S", nil, nil, nil]],
      [:int,       SIZEOF_INT,      nil, true,  ["i", nil, nil, nil]],
      [:uint,      SIZEOF_INT,      nil, true,  ["I", nil, nil, nil]],
      [:unsigned_int,      SIZEOF_INT,      nil, true,  ["I", nil, nil, nil]],
      [:long,      SIZEOF_LONG,     nil, true,  ["l", nil, nil, nil]],
      [:ulong,     SIZEOF_LONG,     nil, true,  ["L", nil, nil, nil]],
      [:unsigned_long,     SIZEOF_LONG,     nil, true,  ["L", nil, nil, nil]],
      [:longlong,  SIZEOF_LONGLONG, nil, true,  ["q", nil, nil, nil]],
      [:long_long,  SIZEOF_LONGLONG, nil, true,  ["q", nil, nil, nil]],
      [:ulonglong, SIZEOF_LONGLONG, nil, true,  ["Q", nil, nil, nil]],
      [:unsigned_long_long, SIZEOF_LONGLONG, nil, true,  ["Q", nil, nil, nil]],
      [:float,     SIZEOF_FLOAT,    nil, true,  ["F", "g", "e", nil]],
      [:double,    SIZEOF_DOUBLE,   nil, true,  ["D", "G", "E", nil]],
      [:size_t,    SIZEOF_SIZE_T,   nil, true,  [FORMATOF_SIZE_T,    nil, nil, nil]],
      [:ssize_t,   SIZEOF_SIZE_T,   nil, true,  [FORMATOF_SSIZE_T,   nil, nil, nil]],
      [:intptr_t,  SIZEOF_INTPTR_T, nil, true,  [FORMATOF_INTPTR_T,  nil, nil, nil]],
      [:uintptr_t, SIZEOF_INTPTR_T, nil, true,  [FORMATOF_UINTPTR_T, nil, nil, nil]],
      [:int8,      1, nil, true, [nil, nil, nil, FORMATOF_INT8_T]],
      [:uint8,     1, nil, true, [nil, nil, nil, FORMATOF_UINT8_T]],
      [:int16,     2, nil, true, [nil, FORMATOF_INT16_BE,  FORMATOF_INT16_LE,  FORMATOF_INT16_T]],
      [:uint16,    2, nil, true, [nil, FORMATOF_UINT16_BE, FORMATOF_UINT16_LE, FORMATOF_UINT16_T]],
      [:int32,     4, nil, true, [nil, FORMATOF_INT32_BE,  FORMATOF_INT32_LE,  FORMATOF_INT32_T]],
      [:uint32,    4, nil, true, [nil, FORMATOF_UINT32_BE, FORMATOF_UINT32_LE, FORMATOF_UINT32_T]],
      [:int64,     8, nil, true, [nil, FORMATOF_INT64_BE,  FORMATOF_INT64_LE,  FORMATOF_INT64_T]],
      [:uint64,    8, nil, true, [nil, FORMATOF_UINT64_BE, FORMATOF_UINT64_LE, FORMATOF_UINT64_T]],
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

  # 名前空間を作ります。
  #
  # 名前空間内ではstructの内部にもtypedefした型名が利用できるため、個別のstruct内でtypedefする労力がなくなります。
  #
  #   HONYARARA = Gogyou.namespace {
  #     self::TYPENAME = struct }
  #       ....
  #     }
  #   }
  #
  # namespace メソッドにブロックを与えた場合で名前空間内に構造体を定義する場合、self::TYPENAME = struct ... とする変わりに struct :TYPENAME ... とシンボル名で置き換えることができます (これは ruby の文法上の仕様に対する機能です)。
  #
  #   HONYARARA = Gogyou.namespace {
  #     struct :TYPENAME {
  #       ....
  #     }
  #   }
  #
  # 名前空間内で定義された (SIZE定数と.pack/.unpackクラスメソッドを持った) クラスのtypedefも不要になります。
  #
  #   HONYARARA = Gogyou.namespace {
  #     # この USERTYPE クラスはHONYARARAモジュール内で定義されるわけではないことに留意すること。
  #     class USERTYPE
  #       SIZE = 1234
  #
  #       def self.pack(value)
  #         .... # 必要に応じて super(value) -> string が利用可能です。
  #         return 文字列 # Array#pack か、それに準ずるバイナリデータ
  #       end
  #
  #       def self.unpack(seq)
  #         ....# 必要に応じて super(seq) -> data が利用可能です。
  #         return typedata # USERTYPE クラスのインスタンス
  #       end
  #     end
  #
  #     # このスコープで USERTYPE 型として定義できるようにする。
  #     typedef USERTYPE, :USERTYPE
  #
  #     # この TYPENAME は HONYARARA モジュール内に定義される
  #     struct :TYPENAME {
  #       USERTYPE :a
  #       ....
  #     }
  #   }
  #
  # 名前空間自体はModuleインスタンスであるので、HONYARARA = Gogyou.namespace した後に module HONYARARA で内部を弄り回すことができます。
  #
  #   HONYARARA = Gogyou.namespace
  #   module HONYARARA
  #     TYPENAME = struct {
  #       ....
  #     }
  #   end
  #
  # また、使い捨て可能なので、局地変数に代入して以下のように記述することも出来ます。
  #
  #   temp = Gogyou.namespace
  #   temp.typedef :uint32_t, HANDLE
  #   X = temp.struct {
  #     HANDLE :a
  #     HANDLE :b
  #   }
  #   temp.typedef X, :X
  #   Y = temp.struct {
  #     X :x1
  #     X :x2
  #   }
  def self.namespace(&block)
    namespace = Namespace.new
    namespace.namespace(&block) if block
    namespace
  end

  NAMESPACE_MAPPING = {} # namespace object (module) => struct farm

  class Namespace < ::Module
    def initialize
      NAMESPACE_MAPPING[self] = StructFarm.new
    end

    def namespace(&block)
      module_eval(&block)
      self
    end

    def struct(name = nil, &block)
      base = NAMESPACE_MAPPING[self]
      include_types(base)
      f = base.clone
      f.instance_eval(&block)
      type = Gogyou.instance_eval { define_struct(f) }
      const_set(name.to_sym, type) if name
      type
    end

    def typedef(target, aliasname)
      base = NAMESPACE_MAPPING[self]
      include_types(base)
      base.typedef(target, aliasname)
      self
    end

    def include_types(base)
      constants.each do |e|
        v = const_get(e)
        next unless v.kind_of?(::Class) && v.const_defined?(:SIZE) &&
          v.respond_to?(:pack) && v.respond_to?(:unpack)
        base.typedef(v, e)
      end
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
