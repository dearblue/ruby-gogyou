module Gogyou
  #
  # 構造体データを構造体として参照させるためのクラスです。
  #
  # このクラスのサブクラスをさらに派生させたクラスが、実際の役目を負います。
  #
  # === クラス関係図
  #
  # リストの入れ子関係は、クラスの親子関係を表します。
  #
  # * Accessor - 基本クラス
  #   * Accessor::BasicStruct - 構造体の基本クラス
  #     * Accessor::Struct - 特定の Model に対する構造体クラス
  #     * Accessor::TemporaryStruct - 汎用的な型情報に対する構造体クラス
  #     * Accessor::BasicUnion - 共用体の基本クラス
  #       * Accessor::Union - 特定の Model に対する共用体クラス
  #       * Accessor::TemporaryUnion - 汎用的な型情報に対する共用体クラス
  #   * Accessor::BasicArray - 配列型の基本クラス
  #     * Accessor::Array - 特定の Model に対する配列型クラス
  #     * Accessor::TemporaryArray - 汎用的な型情報に対する配列型クラス
  #
  class Accessor
    attr_reader :buffer__GOGYOU__
    attr_reader :offset__GOGYOU__

    alias buffer buffer__GOGYOU__
    alias offset offset__GOGYOU__

    def initialize(buffer = String.alloc(self.class::BYTESIZE), offset = 0)
      buffer = String.alloc(buffer.to_i) if buffer.kind_of?(Integer)
      @buffer__GOGYOU__ = buffer
      @offset__GOGYOU__ = offset.to_i
    end

    def initialize_copy(obj)
      super(obj)
      unless obj.frozen?
        @buffer__GOGYOU__ = obj.buffer__GOGYOU__.dup
      end
    end

    #
    # バイナリデータとして取り出します。
    #
    def to_s
      @buffer__GOGYOU__.byteslice(@offset__GOGYOU__, self.class::BYTESIZE)
    end

    def to_buffer
      @buffer__GOGYOU__
    end

    def to_address
      @buffer__GOGYOU__.to_address + @offset__GOGYOU__
    end

    alias to_ptr to_address

    #
    # call-seq:
    #   slide() -> new_accessor or nil
    #   slide(bytesize) -> new_accessor or nil
    #
    # 自身のデータ領域を指定バイト数ずらした参照体を返します。
    #
    def slide(bytesize = 0)
      offset = @offset__GOGYOU__ + self.class::BYTESIZE + bytesize
      self.class.new(@buffer__GOGYOU__, offset)
    end

    #
    # call-seq:
    #   slide!() -> self or nil
    #   slide!(bytesize) -> self or nil
    #
    # 詳細は slide を参照して下さい。
    #
    def slide!(bytesize = 0)
      offset = @offset__GOGYOU__ + self.class::BYTESIZE + bytesize
      @offset__GOGYOU__ = offset
      self
    end

    def bytesize
      self.class::BYTESIZE
    end

    def elementsize
      nil
    end

    def size
      elementsize
    end

    #
    # call-seq:
    #   validate? -> true or false
    #
    # validation for buffer window.
    #
    def validate?
      if @offset__GOGYOU__ + bytesize > @buffer__GOGYOU__.bytesize
        false
      else
        true
      end
    end

    def inspect
      text = "#<#{self.class}"
      bufsize = @buffer__GOGYOU__.bytesize
      self.class::MODEL.fields.each_with_index do |f, i|
        if @offset__GOGYOU__ + f.offset + f.bytesize > bufsize
          text << "#{i > 0 ? "," : ""} #{f.name}=N/A"
        else
          text << "#{i > 0 ? "," : ""} #{f.name}=#{__send__(f.name).inspect}"
        end
      end
      text << ">"
    end

    def pretty_print(q)
      bufsize = @buffer__GOGYOU__.bytesize
      q.group(2, "#<#{self.class}") do
        self.class::MODEL.fields.each_with_index do |f, i|
          q.text "," if i > 0
          q.breakable " "
          if @offset__GOGYOU__ + f.offset + f.bytesize > bufsize
            q.text "#{f.name}=N/A"
          else
            q.group(1, "#{f.name}=") do
              q.breakable ""
              q.pp __send__(f.name)
            end
          end
        end
        q.text ">"
      end
    end

    def self.bind(buffer, offset = 0)
      new(buffer, offset)
    end

    def self.model
      self::MODEL
    end

    def self.define(model)
      klass = ::Class.new(self)
      klass.class_eval do
        const_set(:MODEL, model)
        const_set(:BYTESIZE, model.bytesize)
        const_set(:BYTEALIGN, model.bytealign)
        const_set(:EXTENSIBLE, model.extensible?)
      end

      define_accessors(klass, model)

      klass
    end

    def self.define_subarray(field)
      #sub-array のためのクラスを生成する (多次元配列であれば、それぞれの次元に対して作成)
      #sub-array クラスの MODEL 定数は、Gogyou::Model::Array のインスタンス
      fsize = field.vector.inject(&:*) * field.type.bytesize
      falign = field.type.bytealign
      felements = field.vector[-1]
      raise "BUG: negative element bytesize - #{field.inspect}" unless felements >= 0
      felements = nil if felements == 0
      fvect = field.vector.slice(0 ... -1)
      fvect = nil if fvect.empty?
      subarray = Accessor::Array.define(Model::Array[fsize, falign, [Model::Field[nil, felements, fvect, field.type]]])
      subarray.name # すでに名前が定義されてる場合はこれで固定される
      Accessor.const_set("UserArray_%08X" % subarray.__id__, subarray)
      subarray
    end

    def self.define_subpointer(typeobj, constant = false)
      newtype = Accessor::Pointer.define(typeobj)
      Accessor.const_set("AnonymousPointer_%08X" % newtype.__id__, newtype)
      newtype
    end

    def self.define_accessors(accessorclass, model)
      accessorclass.class_eval do
        namecheck = {}
        fieldsize = model.fields.size
        define_method(:size__GOGYOU__, -> { fieldsize })
        alias_method(:elementsize, :size__GOGYOU__)
        alias_method(:size, :size__GOGYOU__)
        const_set(:GOGYOU_FIELD_TYPES, types = [])
        model.fields.each_with_index do |field, ifield|
          name = field.name
          name = name.intern
          raise NameError, "already exist field name - #{name}" if namecheck[name]
          namecheck[name] = true

          if field.vector
            subarray = define_subarray(field)
            types << subarray
          else
            subarray = nil
            types << field.type
          end

          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{field.name}
              v = GOGYOU_FIELD_TYPES[#{ifield}].aref(@buffer__GOGYOU__, @offset__GOGYOU__ + #{field.offset})
              v.taint if !v.frozen? && (tainted? || @buffer__GOGYOU__.tainted?)
              v.freeze if #{field.const?} || frozen? || @buffer__GOGYOU__.frozen?
              v
            end

            def #{field.name}=(value)
              raise TypeError, "immutable object (#<%s:0x%08X>)" % [self.class, __id__], caller(1) if frozen?
              raise TypeError, "immutable field (#<%s:0x%08X>.%s)" % [self.class, __id__, #{field.name.inspect}], caller(1) if #{field.const?}
              GOGYOU_FIELD_TYPES[#{ifield}].aset(@buffer__GOGYOU__, @offset__GOGYOU__ + #{field.offset}, value)
            end
          EOS
        end
      end
    end

    #
    # 型情報オブジェクトとしてのメソッドです。
    #
    def self.aref(buffer, offset)
      new(buffer, offset)
    end

    #
    # 型情報オブジェクトとしてのメソッドです。
    #
    def self.aset(buffer, offset, data)
      raise NotImplementedError, "IMPLEMENT ME in sub class!"
    end

    #
    # 型情報オブジェクトとしてのメソッドです。
    #
    def self.bytesize
      self::BYTESIZE
    end

    #
    # 型情報オブジェクトとしてのメソッドです。
    #
    def self.bytealign
      self::BYTEALIGN
    end

    #
    # 型情報オブジェクトとしてのメソッドです。
    #
    def self.extensible?
      self::EXTENSIBLE
    end

    class Pointer < Accessor
      BYTESIZE = Primitives::SIZE_T.bytesize
      BYTEALIGN = Primitives::SIZE_T.bytealign
      EXTENSIBLE = false

      def self.aref(buf, off)
        new(buf, off)
      end

      def self.aset(buf, off, val)
        if val.kind_of?(Fixnum)
          buf.store_sizet(off, val)
        else
          raise PointerError, "wrong address (#{val.class} for Fixnum)"
        end

        buf
      end

      def self.define(type)
        require_relative "fiddle" # for Fiddle::Pointer and extend

        Class.new(Pointer) do |t|
          define_singleton_method(:aset, ->(buf, off, val) {
            if val.kind_of?(self)
              addr = val.buffer.load_sizet(val.offset)
              buf.store_sizet(off, addr)
            else
              super
            end

            buf
          })

          define_method(:pointer_address, -> {
            @buffer__GOGYOU__.load_sizet(@offset__GOGYOU__)
          })

          define_method(:[], ->(*args) {
            case args.size
            when 0
              elem = 0
            when 1
              elem = args[0].to_i
            else
              raise ArgumentError, "wrong argument size (#{args.size} for 0 .. 1)"
            end
            addr = @buffer__GOGYOU__.load_sizet(@offset__GOGYOU__)
            if addr == 0
              raise NullPointerError, "nullpo - #<%s:0x%08X>" % [self.class, __id__ << 1]
            end
            buf = ::Fiddle::Pointer.new(addr + elem * type.bytesize, type.bytesize)
            type.aref(buf, 0)
          })

          define_method(:[]=, ->(*args) {
            case args.size
            when 1
              elem = 0
              v = args[0]
            when 2
              elem = args[0].to_i
              v = args[1]
            else
              raise ArgumentError, "wrong argument size (#{args.size} for 1 .. 2)"
            end

            addr = @buffer__GOGYOU__.load_sizet(@offset__GOGYOU__)
            if addr == 0
              raise NullPointerError, "nullpo - #<%s:0x%08X>" % [self.class, __id__ << 1]
            end
            buf = ::Fiddle::Pointer.new(addr + elem * type.bytesize, type.bytesize)
            type.aset(buf, 0, v)
            v
          })

          define_method(:+, ->(elem) {
            addr = @buffer__GOGYOU__.load_sizet(@offset__GOGYOU__)
            buf = String.alloc(Primitives::SIZE_T.bytesize)
            buf.store_sizet(0, addr + elem * type.bytesize)
            self.class.new(buf, 0)
          })

          typename = String(type.respond_to?(:name) ? type.name : type) rescue String(type)
          define_method(:inspect, -> {
            addr = @buffer__GOGYOU__.load_sizet(@offset__GOGYOU__)
            "#<*%s:0x%08X>" % [typename, addr]
          })
        end
      end

      #
      # call-seq:
      #   self + elem_num -> new pointer object
      #
      def +(elem_num)
        raise NotImplementedError, "this method is shall be defined in sub-class"
      end

      def -(off)
        send(:+, -off.to_i)
      end

      def pretty_print(q)
        q.text inspect
      end
    end

    class BasicStruct < Accessor
    end

    class BasicUnion < BasicStruct
    end

    class BasicArray < Accessor
    end

    class Struct < BasicStruct
      def self.aref(buffer, offset)
        new(buffer, offset)
      end

      def self.aset(buffer, offset, data)
        self::MODEL.aset(buffer, offset, data)
      end
    end

    class Union < BasicUnion
    end

    class Array < BasicArray
      include Enumerable

      def self.elements
        self::ELEMENTS
      end

      def self.define(model)
        klass = ::Class.new(self)
        klass.class_eval do
          field = model.fields[0]
          const_set(:MODEL, model)
          const_set(:BYTESIZE, model.bytesize)
          const_set(:BYTEALIGN, model.bytealign)
          const_set(:EXTENSIBLE, model.bytesize == 0 || model.extensible?)
          const_set(:ELEMENTS, elements = field.name)

          vector = field.vector

          if vector
            type = define_subarray(field)
          else
            type = field.type
          end

          if type.kind_of?(::Module)
            # すでに名前が定義されてる場合はこれで固定される
            type.name
          end
          const_set(:SUBTYPE, type)
          bytesize = type.bytesize

          if model.bytesize == 0
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def check_index(index)
                index = index.to_i
                unless index >= 0 && index < elementsize
                  raise IndexError, "out of element size (index \#{index} for 0 ... \#{elementsize})", caller
                end
                index
              end

              def <<(value)
                raise TypeError, "immutable object (#<%s:0x%08X>)" % [self.class, __id__], caller if frozen?
                voff = (@buffer__GOGYOU__.bytesize - @offset__GOGYOU__).align_floor(SUBTYPE.bytesize)
                expandsize = @offset__GOGYOU__ + voff + SUBTYPE.bytesize
                @buffer__GOGYOU__.resize(expandsize)
                SUBTYPE.aset(@buffer__GOGYOU__, @offset__GOGYOU__ + voff, value)
                self
              end

              def elementsize
                (@buffer__GOGYOU__.bytesize - @offset__GOGYOU__).unit_floor(SUBTYPE.bytesize)
              end

              alias size elementsize

              def bytesize
                (@buffer__GOGYOU__.bytesize - @offset__GOGYOU__).align_floor(SUBTYPE.bytesize)
              end
            EOS
          else
            eval <<-EOS
              def check_index(index)
                index = index.to_i
                unless index >= 0 && (#{elements.nil?} || index < #{elements})
                  raise IndexError, "out of element size (index \#{index} for 0 ... #{elements})", caller
                end
                index
              end

              def elementsize
                #{elements}
              end

              alias size elementsize

              def bytesize
                #{type.bytesize * elements}
              end
            EOS
          end

          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def to_s
              @buffer__GOGYOU__.byteslice(@offset__GOGYOU__, bytesize)
            end

            def [](index)
              v = SUBTYPE.aref(@buffer__GOGYOU__, @offset__GOGYOU__ + check_index(index) * #{bytesize})
              v.infect_from(self, @buffer__GOGYOU__) unless v.frozen?
              v.freeze if #{field.const?} || frozen? || @buffer__GOGYOU__.frozen?
              v
            end

            def []=(index, value)
              raise TypeError, "immutable object (#<%s:0x%08X>)" % [self.class, __id__, index], caller if #{field.const?} || frozen?
              SUBTYPE.aset(@buffer__GOGYOU__, @offset__GOGYOU__ + check_index(index) * #{bytesize}, value)
            end
          EOS
        end
        klass
      end

      def self.aset(buffer, offset, value)
        case value
        when ::String
          raise ArgumentError, "buffer size too small" unless value.bytesize <= self::BYTESIZE
          buffer.setbinary(offset, value, 0, self::BYTESIZE)
        when ::Array
          raise NotImplementedError
        when self::SUBTYPE
          raise NotImplementedError
        else
          raise ArgumentError
        end

        value
      end

      def bytesize
        return super unless self.class.extensible?
        self.class::BYTESIZE * @buffer__GOGYOU__.bytesize.unit_floor(self.class::SUBTYPE)
      end

      def each
        return to_enum unless block_given?
        elementsize.times { |i| yield self[i] }
        self
      end

      def each_with_index
        return to_enum(:each_with_index) unless block_given?
        elementsize.times { |i| yield self[i], i }
        self
      end

      def inspect
        text = "["
        elementsize.times.with_index do |n, i|
          text << (i > 0 ? ", " : "") << __send__(:[], n).inspect
        end
        text << "]"
      end

      def pretty_print(q)
        q.group(1, "[") do
          elementsize.times.with_index do |n, i|
            if i > 0
              q.text ","
              q.breakable " "
            end
            q.pp __send__(:[], n)
          end
          q.text "]"
        end
      end
    end

    module TemporaryMixin
      attr_reader :model__GOGYOU__

      def initialize(buffer, offset, model)
        super(buffer, offset)
        @model__GOGYOU__ = model
        self.class.define_accessors(singleton_class, model)
      end

      def inspect
        text = "{"
        model__GOGYOU__.fields.each_with_index do |f, i|
          text << "#{i > 0 ? ", " : ""}#{f.name}=#{__send__(f.name).inspect}"
        end
        text << "}"
      end

      def pretty_print(q)
        q.group(1, "{") do
          model__GOGYOU__.fields.each_with_index do |f, i|
            if i > 0
              q.text ","
              q.breakable " "
            end
            q.group(1, "#{f.name}=") do
              q.breakable ""
              q.pp __send__(f.name)
            end
          end
          q.text "}"
        end
      end
    end

    class TemporaryStruct < BasicStruct
      include TemporaryMixin
    end

    class TemporaryUnion < BasicUnion
      include TemporaryMixin
    end

    class TemporaryArray < BasicArray
      include TemporaryMixin
    end
  end
end
