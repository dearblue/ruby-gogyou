module Gogyou
  #
  # 構造体の構成情報などを保持するクラスです。
  #
  # 構造体の大きさや各フィールドの名前、バイト位置、型などを管理します。
  #
  class Model < ::Struct.new(:bytesize,   # total bytesize in bytes
                             :bytealign,  # byte alignment
                             :fields)     # array of field
    BasicStruct = superclass

    FIELDNAME_PATTERN = /\A[A-Za-z_][0-9A-Za-z_]*\Z/

    undef :bytesize=, :bytealign=, :fields=

    def initialize(*args)
      case
      when args.size < 3
        raise ArgumentError, "wrong argument size (#{args.size} for 3+)"
      when args.size < 4 && args[2].kind_of?(::Array)
        super
      else
        super(args[0], args[1], args.slice(2 .. -1))
      end
    end

    def aset(buffer, offset, value)
      raise NotImplementedError
    end

    def aref(buffer, offset)
      raise NotImplementedError
    end

    def extensible?
      fields.any? { |f| f.extensible? }
    end

    def to_s
      "#{self.class}[bytesize=#{bytesize.inspect}, bytealign=#{bytealign.inspect}, fields=#{fields.inspect}]"
    end

    alias inspect to_s

    def pretty_print(q)
      #bytesize, bytealign, fields
      q.group(1, "#{self.class}[") do
        #q.breakable
        q.text "bytesize="
        q.pp bytesize
        q.text ", "
        #q.breakable
        q.text "bytealign="
        q.pp bytealign
        q.text ", "
        #q.breakable(" ")
        q.text "fields="
        q.breakable
        q.pp fields
      end
      q.text "]"
    end

    # 構造体の各メンバの情報を保持する
    class Field < ::Struct.new(:offset, # field offset in model
                               :name,   # field name
                               :vector, # 要素数。任意数配列の場合は 0。配列でないならば nil。
                               :type,   # type specification (or model object) of this field
                               :flags)  # 0x01: const / 0x02: packed (not aligned)
      BasicStruct = superclass

      FLAG_CONST  = 0x01
      FLAG_PACKED = 0x02

      def initialize(offset, name, vector, type, flags = 0)
        super(offset, name, vector, type, flags)
      end

      def extensible?
        if vector
          vector[-1] == 0 ? true : false
        else
          type.extensible?
        end
      end

      def const?
        ((flags & FLAG_CONST) == FLAG_CONST) ? true : false
      end

      def packed?
        ((flags & FLAG_PACKED) == FLAG_PACKED) ? true : false
      end

      def mark_const
        self.flags |= FLAG_CONST
        self
      end

      def mark_packed
        self.flags |= FLAGS_PACKED
        self
      end

      def strflags
        set = [const? ? "const" : nil, packed? ? "packed" : nil]
        set.compact!
        return nil if set.empty?
        set.join(",")
      end

      def strflags_with_paren
        set = strflags
        set ? "(#{set})" : ""
      end

      def to_s
        "#{self.class}[offset=#{offset.inspect}, name=#{name.inspect}, vector=#{vector.inspect}, type=#{type.inspect}, flags=0x#{flags.to_s(16)}#{strflags_with_paren}]"
      end

      alias inspect to_s

      def pretty_print(q)
        q.group(1, "#{self.class}[") do
          #q.breakable
          q.text "offset="
          q.pp offset
          q.text ", "
          #q.breakable
          q.text "name="
          q.pp name
          q.text ", "
          #q.breakable
          q.text "vector="
          q.pp vector
          q.text ", "
          #q.breakable
          q.text "flags=0x%02x%s" % [flags, strflags_with_paren]
          q.text ","
          q.breakable(" ")
          q.text "type="
          q.pp type
        end
        q.text "]"
      end
    end

    def self.struct(typemap, &block)
      define_container(typemap, Model::Struct, &block)
    end

    def self.union(typemap, &block)
      define_container(typemap, Model::Union, &block)
    end

    def self.typedef(typemap, type, aliasname, *elements)
      raise ArgumentError, "informal aliasname (#{aliasname.inspect})" unless aliasname =~ FIELDNAME_PATTERN
      aliasname = aliasname.intern

      case type
      when Symbol, String
        type0 = type
        type = typemap[type.intern]
        raise ArgumentError, "type not defined (#{type0})" unless type
      else
        # 型情報子を用いる方法
        raise ArgumentError, "type is not typeinfo (#{type.inspect})" unless Model.check_typeinfo(type)
      end

      unless elements.empty?
        # 配列型
        # TODO: Accessor::Array を構築するのではなく、Model::Array インスタンスを生成するようにする
        type = Accessor.define_subarray(Model::Field[0, nil, elements, type, 0])
      end

      typemap[aliasname] = type

      nil
    end

    def self.define_container(typemap, model_type, &block)
      creator = model_type::Creator.new(typemap, 0, [])
      proxy = model_type::Creator::Proxy.new(creator)
      proxy.instance_exec(&block)
      model = creator.to_model
      model
    end

    def self.check_typeinfo(obj)
      if obj.kind_of?(Model) ||
         (obj.kind_of?(Module) && obj < Accessor) ||
         (obj.respond_to?(:bytesize) &&
          obj.respond_to?(:bytealign) &&
          obj.respond_to?(:extensible?) &&
          obj.respond_to?(:aset) &&
          obj.respond_to?(:aref))
        true
      else
        false
      end
    end


    BasicCreator = ::Struct.new(:typemap, :offset, :fields)

    class BasicCreator
      def maxalign(fields = self.fields)
        fields.map { |f| f.type.bytealign }.max
      end

      def maxsize(fields = self.fields)
        fields.map { |f| s = f.type.bytesize; f.vector ? f.vector.inject(&:*) * s : s }.max
      end

      def flatten_field(fields = self.fields)
        #pp fields
        fields2 = []
        fields.each do |f|
          #p f
          #p f.class
          if f.name
            fields2 << f
          else
            raise "BUG? : field.type is not a Model (%p)" % f.type unless f.type.kind_of?(Model)
            fs = flatten_field(f.type.fields)
            fs.each { |ff| ff.offset += f.offset; ff.mark_const if f.const? }
            fields2.concat fs
          end
        end
        fields2
      end

      # :nodoc: all
      class Proxy < Object
      #class Proxy < BasicObject
        def initialize(creator)
          #singleton_class = (class << proxy; self; end)
          singleton_class.class_eval do
            latest_fields = nil
            #define_method(:method_missing, ->(type, *args) { latest_fields = creator.addfield(type, args); nil })
            creator.typemap.each_key do |t|
              define_method(t, ->(*args) { latest_fields = creator.addfield(t, args); nil })
              tt = :"#{t}!"
              define_method(tt, ->(*args) { latest_fields = creator.addfield(tt, args); nil })
            end
            define_method(:struct, ->(*args, &block) { latest_fields = creator.struct(args, &block); nil })
            define_method(:union, ->(*args, &block) { latest_fields = creator.union(args, &block); nil })
            define_method(:const, ->(dummy_fields) { creator.const(latest_fields); latest_fields = nil; nil })
            define_method(:typedef, ->(*args, &block) { creator.typedef(args, &block) })
            if creator.respond_to?(:bytealign)
              define_method(:bytealign, ->(bytesize, &block) { creator.bytealign(bytesize, &block) })
            end
            if creator.respond_to?(:padding)
              define_method(:padding, ->(bytesize, &block) { creator.padding(bytesize, &block) })
            end
          end
        end
      end

      #
      # call-seq:
      #   struct type, name, *vector
      #   struct proc, name, *vector
      #   struct { ... }
      #
      # 最初の呼び出し方法は、既存の (typedef していない) 型情報を用いる、または構造体をその場で定義するために利用できます。
      #
      # 二番目の呼び出し方法は、無名構造体を定義するために利用できます。
      #
      # === example (型情報を用いる)
      #
      #   Type1 = struct {
      #     struct UserType, :a, :b, 2, 3, 4
      #   }
      #
      # === example (構造体をその場で定義して、構造体へのアクセッサを定義する)
      #
      #   Type2 = struct {
      #     struct -> {
      #       int :x, y, z
      #     }, :a, :b, 2, 3, 4
      #   }
      #
      # === example (無名構造体)
      #
      #   Type3 = struct {
      #     struct {
      #       int :a, :b, 2, 3, 4
      #     }
      #   }
      #
      def struct(args, &block)
        define_container(args, block, Model.method(:struct))
      end

      #
      # call-seq:
      #   union type, name, *vector
      #   union proc, name, *vector
      #   union { ... }
      #
      # 共用体を定義します。
      #
      # 呼び出し方は struct と変わりません。
      #
      # ただ、<tt>union type, ...</tt> の場合は、<tt>struct type, ...</tt> と同じ結果となります。
      # これは type がどのような構造になっているのかを gogyou が管理も把握もしないためです。
      # この記述ができる唯一の理由は、人間が見てわかりやすくすることを意図しています
      # (ただし、ミスリードを誘う手口にも利用されてしまうのが最大の欠点です)。
      #
      def union(args, &block)
        define_container(args, block, Model.method(:union))
      end

      def define_container(args, anonymblock, container)
        if anonymblock
          raise ArgumentError, "given block and arguments" unless args.empty?
          model = container.(typemap.dup, &anonymblock)
          raise "BUG - object is not a Model (#{model.class})" unless model.kind_of?(Model)
          #p model: model, superclass: model.superclass
          self.offset = offset.align_ceil(model.bytealign) unless kind_of?(Model::Union::Creator)
          fields << f = Field[offset, nil, nil, model, 0]
          self.offset += model.bytesize unless kind_of?(Model::Union::Creator)
          [f]
        else
          type = args.shift
          type = container.(typemap.dup, &type) if type.kind_of?(::Proc)
          addfield!(type, args)
        end
      end

      def typedef(args)
        raise NotImplementedError
      end

      def const(fields)
        fields.each { |f| f.mark_const }
      end

      #
      # フィールド名の解析
      #
      def parse!(args)
        raise ArgumentError, "nothing argument" if args.empty?
        name = nil
        vector = nil
        while arg = args.shift
          case arg
          when Symbol, String
            yield(name, vector) if name
            raise ArgumentError, "informal field name (#{arg.to_s})" unless arg =~ FIELDNAME_PATTERN
            name = arg.intern
            vector = nil
          when Integer
            raise ArgumentError, "first argument is field name only (#{arg})" unless name
            raise ArgumentError, "given negative number (#{arg})" unless arg >= 0
            vector ||= []
            vector << arg.to_i
            if vector[-1] == 0
              yield(name, vector)
              unless args.empty?
                raise ArgumentError, "given fields after extensible vector"
              end
              return nil
            end
          else
            raise ArgumentError, "given any object (#{arg.inspect})"
          end
        end

        yield(name, vector)

        nil
      end

      def addfield(type, args)
        typeobj = typemap[type.intern]
        unless typeobj
          typeobj = typemap[type.to_s.sub(/!$/, "").intern]
          unless typeobj
            raise NoMethodError, "typename or method is missing (#{type})"
          end
        end

        addfield!(typeobj, args)
      end

      def addfield!(typeobj, args)
        #p typeobj
        # check extensible field  >>>  creator.fields[-1].vector[-1]
        if (x = fields[-1]) && (x = x.vector) && x[-1] == 0
          raise ArgumentError, "not given fields after extensible vector"
        end

        typesize = typeobj.bytesize
        typealign = typeobj.bytealign

        tmpfields = []

        parse!(args) do |name, vect|
          self.offset = offset.align_ceil(typealign) unless kind_of?(Model::Union::Creator)
          fields << f = Field[offset, name, vect, typeobj, 0]
          tmpfields << f
          unless kind_of?(Model::Union::Creator)
            elements = vect ? vect.inject(1, &:*) : 1
            self.offset += typesize * elements
          end
        end

        tmpfields
      end
    end

    class Struct < Model
      class Creator < Model::BasicCreator
        def bytealign(bytesize)
          raise NotImplementedError
        end

        def padding(bytesize)
          raise NotImplementedError
        end

        def to_model
          Model::Struct.new(offset.align_ceil(maxalign), maxalign, flatten_field)
        end
      end

      def aset(buffer, offset, value)
        raise NotImplementedError
      end

      def aref(buffer, offset)
        v = Accessor::TemporaryStruct.new(buffer, offset, self)
        v.infect_from(self, buffer) unless v.frozen?
        v.freeze if frozen? || buffer.frozen?
        v
      end

      def create_accessor
        Accessor::Struct.define(self)
      end
    end

    class Union < Model
      class Creator < Model::BasicCreator
        def to_model
          Model::Union.new(maxsize.align_ceil(maxalign), maxalign, flatten_field)
        end
      end

      def aset(buffer, offset, value)
        raise NotImplementedError
      end

      def aref(buffer, offset)
        v = Accessor::TemporaryUnion.new(buffer, offset, self)
        v.infect_from(self, buffer) unless v.frozen?
        v.freeze if frozen? || buffer.frozen?
        v
      end

      def create_accessor
        Accessor::Union.define(self)
      end
    end

    #
    # C の配列を模造するクラス。
    #
    class Array < Model
      def extensible?
        fields[-1] == 0 ? true : false
      end

      def aset(buffer, offset, value)
        raise NotImplementedError
      end

      def aref(buffer, offset)
        raise NotImplementedError
        accessor = Accessor::Array[buffer, offset, self]
        accessor.instance_eval do
          field = fields[0]
          type = field.type
          elements = field.vector[-1]

          define_singleton_method(:check_index, ->(i) {
            i = i.to_i
            raise IndexError unless i >= 0 && (elements.nil? || i < elements)
            i
          })

          define_singleton_method(:[], ->(i) {
            v = type.aref(buffer__GOGYOU__, offset__GOGYOU__ + type.bytesize * check_index(i))
            v.infect_from(self, buffer) unless v.frozen?
            v.freeze if frozen? || buffer.frozen? || field.const?
            v
          })

          define_singleton_method(:[]=, ->(i, v) {
            type.aset(buffer__GOGYOU__, offset__GOGYOU__ + type.bytesize * check_index(i), v)
          })
        end
        accessor
      end
    end
  end
end
