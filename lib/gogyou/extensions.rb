#vim set fileencoding:utf-8

require_relative "typespec"
require_relative "bytearray"

module Gogyou
  module Aux
    def self.define_pack_binary(mod, name, bitsize, exponent_bitsize, fraction_bitsize)
      sign_bit = 1 << (fraction_bitsize + exponent_bitsize)
      fraction_bitmask = ~(~0 << fraction_bitsize)
      exponent_bitmask = ~(~0 << exponent_bitsize)
      exponent_bias = (exponent_bitmask >> 1) - 1
      exponent_max = (exponent_bitmask >> 1) + 2
      exponent_min = -exponent_max
      fraction_msb = 1 << fraction_bitsize
      fraction_bias = 1 << (fraction_bitsize + 1)
      nan = (exponent_bitmask << fraction_bitsize) | (fraction_msb >> 1)
      infinity = (exponent_max + exponent_bias) << fraction_bitsize

      mod.module_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def #{name}
          num = Float(self)

          return #{nan} if num.nan?

          n = (num < 0 || (1 / num) < 0) ? #{sign_bit} : 0
          return n if num == 0

          return n | #{infinity} if num.infinite?

          num = -num unless n == 0
          (coefficient, e) = Math.frexp(num)
          case
          when e > #{exponent_max}
            n | #{infinity}
          when e < #{exponent_min}
            n
          else
            coefficient = (coefficient * #{fraction_bias}).to_i
            n |= ((e + #{exponent_bias}) & #{exponent_bitmask}) << #{fraction_bitsize}
            n | coefficient & #{fraction_bitmask}
          end
        end
      EOS
    end

    def self.define_unpack_binary(mod, name, bitsize, exponent_bitsize, fraction_bitsize)
      sign_bit = 1 << (fraction_bitsize + exponent_bitsize)
      fraction_bitmask = ~(~0 << fraction_bitsize)
      exponent_bitmask = ~(~0 << exponent_bitsize)
      exponent_bias = (exponent_bitmask >> 1) - 1
      fraction_msb = 1 << fraction_bitsize
      fraction_bias = (1 << (fraction_bitsize + 1)).to_f

      mod.module_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def #{name}
          n = self.to_i
          e = (n >> #{fraction_bitsize}) & #{exponent_bitmask}
          s = (n & #{sign_bit}) != 0
          case e
          when 0
            return s ? -0.0 : 0.0
          when #{exponent_bitmask}
            if (n & #{fraction_bitmask}) != 0
              return Float::NAN
            else
              return s ? -Float::INFINITY : Float::INFINITY
            end
          end

          e -= #{exponent_bias}
          c = ((n & #{fraction_bitmask}) | #{fraction_msb}) / #{fraction_bias}
          num = Math.ldexp(c, e)
          num = -num if s

          num
        end
      EOS
    end
  end

  module Extensions
    module ObjectClass
    end

    module Object
      def infect_from(*obj)
        obj.each { |o| taint if o.tainted? }
        self
      end
    end

    class ::Object
      extend Gogyou::Extensions::ObjectClass
      include Gogyou::Extensions::Object
    end

    UNIT_B   = 1 << 0
    UNIT_KiB = 1 << 10
    UNIT_MiB = 1 << 20
    UNIT_GiB = 1 << 30
    UNIT_TiB = 1 << 40
    UNIT_PiB = 1 << 50
    UNIT_EiB = 1 << 60
    UNIT_ZiB = 1 << 70
    UNIT_YiB = 1 << 80

    module NumericClass
    end

    module Numeric
      def B
        UNIT_B * self
      end

      def KiB
        UNIT_KiB * self
      end

      def MiB
        UNIT_MiB * self
      end

      def GiB
        UNIT_GiB * self
      end

      def TiB
        UNIT_TiB * self
      end

      def PiB
        UNIT_PiB * self
      end

      def EiB
        UNIT_EiB * self
      end

      def ZiB
        UNIT_ZiB * self
      end

      def YiB
        UNIT_YiB * self
      end

      def unit_floor(unit)
        (self / unit).to_i
      end

      def unit_ceil(unit)
        ((self + (unit - 1)) / unit).to_i
      end

      def align_floor(unit)
        ((self / unit).to_i * unit).to_i
      end

      def align_ceil(unit)
        (((self + (unit - 1)) / unit).to_i * unit).to_i
      end

      Aux.define_pack_binary(self, :pack_binary16, 16, 5, 10)
      #
      # pack to IEEE 754 Half precision (16 bits; 5 bit exponents, 10 bit fractions)
      #
      # SEE Gogyou::Aux.define_pack_binary FOR IMPLEMENTATION.
      #
      def pack_binary16
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false

      Aux.define_pack_binary(self, :pack_binary32, 32, 8, 23)
      #
      # pack to IEEE 754 Single precision (32 bits; 8 bit exponents, 23 bit fractions)
      #
      # SEE Gogyou::Aux.define_pack_binary FOR IMPLEMENTATION.
      #
      def pack_binary32
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false

      Aux.define_pack_binary(self, :pack_binary64, 64, 11, 52)
      #
      # pack to IEEE 754 Double precision (64 bits; 11 bit exponents, 52 bit fractions)
      #
      # SEE Gogyou::Aux.define_pack_binary FOR IMPLEMENTATION.
      #
      def pack_binary64
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false

      Aux.define_unpack_binary(self, :unpack_binary16, 16,  5, 10)
      #
      # unpack to IEEE 754 Half precision (16 bits; 5 bit exponents, 10 bit fractions)
      #
      # SEE Gogyou::Aux.define_unpack_binary FOR IMPLEMENTATION.
      #
      def unpack_binary16
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false

      Aux.define_unpack_binary(self, :unpack_binary32, 32,  8, 23)
      #
      # unpack to IEEE 754 Single precision (32 bits; 8 bit exponents, 23 bit fractions)
      #
      # SEE Gogyou::Aux.define_unpack_binary FOR IMPLEMENTATION.
      #
      def unpack_binary32
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false

      Aux.define_unpack_binary(self, :unpack_binary64, 64, 11, 52)
      #
      # unpack to IEEE 754 Double precision (64 bits; 11 bit exponents, 52 bit fractions)
      #
      # SEE Gogyou::Aux.define_unpack_binary FOR IMPLEMENTATION.
      #
      def unpack_binary64
        THIS IS FAKED IMPLEMENTATION FOR RDOC
      end if false
    end

    class ::Numeric
      extend Gogyou::Extensions::NumericClass
      include Gogyou::Extensions::Numeric
    end

    module IntegerClass
      module_function
      def bitmask(shift, bits)
        ~(~0 << bits) << shift
      end

      public :bitmask
      public_class_method :bitmask
    end

    module Integer
      extend IntegerClass

      def getbit(shift, bits)
        (self >> shift) & Integer.bitmask(0, bits)
      end

      def getbits(shift, bits)
        getbit(shift, bits).extendsign(bits)
      end

      def getbitset(*bitsize)
        shift = 0
        list = []
        bitsize.each do |bits|
          if bits > 0
            list << getbit(shift, bits)
            shift += bits
          else
            list << 0
          end
        end
        list
      end

      def setbit(shift, bits, num)
        mask = Integer.bitmask(shift, bits)
        (self & ~mask) | ((num << shift) & mask)
      end

      def extendsign(bits)
        n = self & Integer.bitmask(0, bits)
        if (n >> (bits - 1)) == 0
          n
        else
          n | (~0 << bits)
        end
      end

      def extendsign_char
        ((self & 0xff) ^ 0x80) - 0x80
      end

      def swapbyte(bytesize)
        num = 0
        bytesize.times do |i|
          num <<= 8
          num |= (self >> (i * 8)) & 0xff
        end
        num
      end

      def swap16
        n = self & 0xffff
        ((n >> 8) & 0xff) | ((n & 0xff) << 8)
      end

      def swap16s
        n = self & 0xffff
        ((n >> 8) & 0xff) | ((n & 0xff).extendsign_char << 8)
      end

      def swap24
        n = self & 0xffffff
        ((n >> 16) & 0xff) |
          (n & 0xff00) |
          ((n & 0xff) << 16)
      end

      def swap24s
        n = self & 0xffffff
        ((n >> 16) & 0xff) |
          (n & 0xff00) |
          ((n & 0xff).extendsign_char << 16)
      end

      def swap32
        n = self & 0xffffffff
        ((n >> 24) & 0xff) |
          ((n >> 8) & 0xff00) |
          ((n & 0xff00) << 8) |
          ((n & 0xff) << 24)
      end

      def swap32s
        n = self & 0xffffffff
        ((n >> 24) & 0xff) |
          ((n >> 8) & 0xff00) |
          ((n & 0xff00) << 8) |
          ((n & 0xff).extendsign_char << 24)
      end

      def swap48
        n = self & 0xffffffffffff
        ((n >> 40) & 0xff) |
          ((n >> 24) & 0xff00) |
          ((n >> 8) & 0xff0000) |
          ((n & 0xff0000) << 8) |
          ((n & 0xff00) << 24) |
          ((n & 0xff) << 40)
      end

      def swap48s
        n = self & 0xffffffffffff
        ((n >> 40) & 0xff) |
          ((n >> 24) & 0xff00) |
          ((n >> 8) & 0xff0000) |
          ((n & 0xff0000) << 8) |
          ((n & 0xff00) << 24) |
          ((n & 0xff).extendsign_char << 40)
      end

      def swap64
        n = self & 0xffffffffffffffff
        ((n >> 56) & 0xff) |
          ((n >> 40) & 0xff00) |
          ((n >> 24) & 0xff0000) |
          ((n >> 8) & 0xff000000) |
          ((n & 0xff000000) << 8) |
          ((n & 0xff0000) << 24) |
          ((n & 0xff00) << 40) |
          ((n & 0xff) << 56)
      end

      def swap64s
        n = self & 0xffffffffffffffff
        ((n >> 56) & 0xff) |
          ((n >> 40) & 0xff00) |
          ((n >> 24) & 0xff0000) |
          ((n >> 8) & 0xff000000) |
          ((n & 0xff000000) << 8) |
          ((n & 0xff0000) << 24) |
          ((n & 0xff00) << 40) |
          ((n & 0xff).extendsign_char << 56)
      end

      def swap96
        (swap48 << 48) | (self >> 48).swap48
      end

      def swap96s
        (swap48s << 48) | (self >> 48).swap48
      end

      def swap128
        (swap64 << 64) | (self >> 64).swap64
      end

      def swap128s
        (swap64s << 64) | (self >> 64).swap64
      end
    end

    class ::Integer
      extend Gogyou::Extensions::IntegerClass
      include Gogyou::Extensions::Integer
    end

    module StringClass
      BITS_PER_BYTE = 8

      module_function
      def malloc(bytesize)
        ?\0.force_encoding(Encoding::BINARY) * bytesize
      end

      public :malloc

      alias alloc malloc

      class << self
        alias alloc malloc
      end
    end

    module String
      def to_address
        [self].pack("p").load_sizet(0)
      end

      alias to_ptr to_address

      def binary_operation
        enc = encoding
        force_encoding(Encoding::BINARY)
        begin
          yield
        ensure
          force_encoding(enc) rescue nil if enc
        end
      end

      def resize(newsize)
        binary_operation do
          left = newsize - bytesize
          case
          when left > 0
            while left >= ZERO_BUFFER.bytesize
              concat(ZERO_BUFFER)
              left -= ZERO_BUFFER.bytesize
            end
            if left > 0
              zero = ZERO_BUFFER[ZERO_BUFFER.bytesize - left, left] # make shared string
              concat(zero)
            end
          when left < 0
            left = - left
            self[bytesize - left, left] = ""
          end
        end

        self
      end

      def setbinary(index, mem, offset = 0, size = mem.bytesize)
        offset = offset.to_i
        size = size.to_i
        size1 = mem.bytesize - offset
        size = size1 if size > size1
        if size > 0
          binary_operation do
            self[index.to_i, size] = mem.byteslice(offset, size)
          end
        end

        self
      end
    end

    ZERO_BUFFER = StringClass.malloc(64.KiB).freeze
  end
end

class ::String
  extend Gogyou::Extensions::StringClass
  include Gogyou::Extensions::String
  include Gogyou::Extensions::ByteArray
end
