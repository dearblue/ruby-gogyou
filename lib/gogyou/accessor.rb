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
      buffer__GOGYOU__.byteslice(offset__GOGYOU__, self.class::BYTESIZE)
    end

    def to_buffer
      buffer__GOGYOU__
    end

    def to_ptr
      buffer__GOGYOU__.to_ptr
    end

    #
    # call-seq:
    #   slide() -> new_accessor or nil
    #   slide(bytesize) -> new_accessor or nil
    #
    # 自身のデータ領域を指定バイト数ずらした参照体を返します。
    #
    def slide(bytesize = self.class::BYTESIZE)
      self.class.new(buffer__GOGYOU__, offset__GOGYOU__ + bytesize)
    end

    #
    # call-seq:
    #   slide!() -> self or nil
    #   slide!(bytesize) -> self or nil
    #
    # 詳細は slide を参照して下さい。
    #
    def slide!(bytesize = self.class::BYTESIZE)
      offset = offset__GOGYOU__ + bytesize
      #return nil if offset < 0
      #return nil if offset + buffer__GOGYOU__.bytesize > layout__GOGYOU__.bytesize
      @offset__GOGYOU__ = offset
      self
    end

    def bytesize
      self.class::BYTESIZE
    end

    def size
      nil
    end

    def inspect
      "#<%s buffer=%p, offset=%p>" % [self.class,
                                      buffer__GOGYOU__,
                                      offset__GOGYOU__]
    end

    def pretty_print(q)
      q.group(1, "#<#{self.class}") do
        q.breakable " "
        q.text "buffer="
        q.pp buffer__GOGYOU__
        q.text ","
        q.breakable " "
        q.text "offset="
        q.pp offset__GOGYOU__
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

    def self.define_accessors(accessorclass, model)
      accessorclass.class_eval do
        namecheck = {}
        model.fields.each do |field|
          name = field.name
          #raise NameError, "wrong field name - #{name}" unless name =~ /\A[A-Za-z_][A-Za-z_0-9]*\Z/
          name = name.intern
          raise NameError, "already exist field name - #{name}" if namecheck[name]
          namecheck[name] = true

          if field.vector
            subarray = define_subarray(field)
            type = subarray
          else
            subarray = nil
            type = field.type
          end

          define_method(field.name, -> {
            v = type.aref(buffer__GOGYOU__, offset__GOGYOU__ + field.offset)
            v.infect_from(self, buffer) unless v.frozen?
            v.freeze if frozen? || buffer.frozen? || field.const?
            v
          })

          define_method("#{field.name}=", ->(value) {
            raise TypeError, "immutable object (#<%s:0x%08X>.%s)" % [self.class, __id__, field.name], caller(2) if frozen?
            raise TypeError, "immutable field (#<%s:0x%08X>.%s)" % [self.class, __id__, field.name], caller(2) if field.const?
            type.aset(buffer__GOGYOU__, offset__GOGYOU__ + field.offset, value)
          })
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
            check_index = ->(index) do
              index = index.to_i
              unless index >= 0 && index < self.size
                raise IndexError, "out of element size (index #{index} for 0 ... #{self.size})", caller(2)
              end
              index
            end

            define_method(:<<, ->(value) {
              raise TypeError, "immutable object (#<%s:0x%08X>)" % [self.class, __id__], caller(2) if frozen?
              voff = (buffer__GOGYOU__.bytesize - offset__GOGYOU__).align_floor(type.bytesize)
              expandsize = offset__GOGYOU__ + voff + type.bytesize
              buffer__GOGYOU__.resize(expandsize)
              type.aset(buffer__GOGYOU__, offset__GOGYOU__ + voff, value)
              self
            })

            define_method(:size, -> {
              (buffer__GOGYOU__.bytesize - offset__GOGYOU__).unit_floor(type.bytesize)
            })

            define_method(:bytesize, -> {
              (buffer__GOGYOU__.bytesize - offset__GOGYOU__).align_floor(type.bytesize)
            })
          else
            check_index = ->(index) do
              index = index.to_i
              unless index >= 0 && (elements.nil? || index < elements)
                raise IndexError, "out of element size (index #{index} for 0 ... #{elements})", caller(2)
              end
              index
            end

            eval <<-EOS
              def bytesize
                #{elements}
              end
            EOS
          end

          define_method(:to_s, -> {
            buffer__GOGYOU__.byteslice(offset__GOGYOU__, bytesize)
          })

          define_method(:[], ->(index) {
            v = type.aref(buffer__GOGYOU__, offset__GOGYOU__ + check_index.(index) * bytesize)
            v.infect_from(self, buffer) unless v.frozen?
            v.freeze if frozen? || buffer.frozen? || field.const?
            v
          })

          define_method(:[]=, ->(index, value) {
            raise TypeError, "immutable object (#<%s:0x%08X>)" % [self.class, __id__, index], caller(2) if frozen? or field.const?
            type.aset(buffer__GOGYOU__, offset__GOGYOU__ + check_index.(index) * bytesize, value)
          })
        end
        klass
      end

      def self.aset(buffer, offset, value)
        case value
        when ::String
          raise ArgumentError, "buffer size too small" unless value.bytesize < self::BYTESIZE
          buffer.setbinary(offset, value, self::BYTESIZE, 0)
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
        self.class::BYTESIZE * buffer__GOGYOU__.bytesize.unit_floor(self.class::SUBTYPE)
      end
    end

    module TemporaryMixin
      attr_reader :model__GOGYOU__

      def initialize(buffer, offset, model)
        super(buffer, offset)
        @model__GOGYOU__ = nil
        self.class.define_accessors(singleton_class, model)
      end

      def inspect
        "#<%s buffer=%p, offset=%p, model=%p>" % [self.class,
                                                  buffer__GOGYOU__,
                                                  offset__GOGYOU__,
                                                  model__GOGYOU__]
      end

      def pretty_print(q)
        q.group(1, "#<#{self.class}") do
          q.breakable " "
          q.text "buffer="
          q.pp buffer__GOGYOU__
          q.text ","
          q.breakable " "
          q.text "offset="
          q.pp offset__GOGYOU__
          q.text ","
          q.breakable " "
          q.text "model="
          q.pp model__GOGYOU__ #|| self.class.model
          q.text ">"
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
