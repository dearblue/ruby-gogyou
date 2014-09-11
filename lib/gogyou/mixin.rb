#vim set fileencoding:utf-8

require_relative "typespec"

module Gogyou
  module Extensions
    module Object
      module Mixin
        def infect_from(*obj)
          obj.each { |o| taint if o.tainted? }
          self
        end
      end
    end

    class ::Object
      extend Gogyou::Extensions::Object
      include Gogyou::Extensions::Object::Mixin
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

    module Numeric
      module Mixin
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
      end
    end

    class ::Numeric
      extend Gogyou::Extensions::Numeric
      include Gogyou::Extensions::Numeric::Mixin
    end

    module Integer
      module_function
      def bitmask(shift, bits)
        ~(~0 << bits) << shift
      end

      public_class_method :bitmask

      module Mixin
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

        def swapbyte(bytesize)
          num = 0
          bytesize.times do |i|
            num <<= 8
            num |= (self >> (i * 8)) & 0xff
          end
          num
        end

        def swap16
          ((self >> 8) & 0xff) | ((self & 0xff) << 8)
        end

        def swap24
          ((self >> 16) & 0xff) |
            (self & 0xff00) |
            ((self & 0xff) << 16)
        end

        def swap32
          ((self >> 24) & 0xff) |
            ((self >> 8) & 0xff00) |
            ((self & 0xff00) << 8) |
            ((self & 0xff) << 24)
        end

        def swap48
          ((self >> 40) & 0xff) |
            ((self >> 24) & 0xff00) |
            ((self >> 8) & 0xff0000) |
            ((self & 0xff0000) << 8) |
            ((self & 0xff00) << 24) |
            ((self & 0xff) << 40)
        end

        def swap64
          ((self >> 56) & 0xff) |
            ((self >> 40) & 0xff00) |
            ((self >> 24) & 0xff0000) |
            ((self >> 8) & 0xff000000) |
            ((self & 0xff000000) << 8) |
            ((self & 0xff0000) << 24) |
            ((self & 0xff00) << 40) |
            ((self & 0xff) << 56)
        end
      end
    end

    class ::Integer
      extend Gogyou::Extensions::Integer
      include Gogyou::Extensions::Integer::Mixin
    end

    module String
      BITS_PER_BYTE = 8

      module_function
      def alloc(bytesize)
        ?\0.force_encoding(Encoding::BINARY) * bytesize
      end

      public :alloc

      ZERO_BUFFER = alloc(64.KiB).freeze

      module Mixin
        def to_ptr
          [self].pack("p").load_sizet(0)
        end

        def binary_operation
          enc = encoding
          force_encoding(Encoding::BINARY) rescue (enc = nil; raise)
          yield
        ensure
          force_encoding(enc) rescue nil if enc
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
              concat(ZERO_BUFFER[ZERO_BUFFER.bytesize - left, left]) # make shared string
            when left < 0
              left = - left
              self[bytesize - left, left] = ""
            end
          end

          self
        end

        def setbinary(index, str, bytesize = str.bytesize, offset = 0)
          offset = offset.to_i
          bytesize = bytesize.to_i
          size1 = str.bytesize - offset
          bytesize = size1 if bytesize > size1
          if bytesize > 0
            binary_operation do
              self[index.to_i, bytesize] = str.byteslice(offset, bytesize)
            end
          end

          self
        end

        def swapbyte(index, bytesize)
          i = index.to_i
          j = i + bytesize.to_i - 1
          while i < j
            w = getbyte(i)
            setbyte(i, getbyte(j))
            setbyte(j, w)
            i += 1
            j -= 1
          end

          self
        end

        def storebe(index, num, bytesize)
          raise RangeError unless index >= 0 &&
                                  index < bytesize &&
                                  index + bytesize <= bytesize &&
                                  index + bytesize >= 0
          while bytesize > 0
            bytesize -= 1
            setbyte(index, 0xff & (num >> (bytesize * BITS_PER_BYTE)))
            index += 1
          end

          self
        end

        def storele(index, num, bytesize)
          raise RangeError unless index >= 0 &&
                                  index < bytesize &&
                                  index + bytesize <= bytesize &&
                                  index + bytesize >= 0
          while bytesize > 0
            bytesize -= 1
            setbyte(index, 0xff & num)
            num >>= BITS_PER_BYTE
            index += 1
          end

          self
        end

        def loadube(index, bytesize)
          n = 0
          while bytesize > 0
            bytesize -= 1
            n <<= BITS_PER_BYTE
            n |= getbyte(index)
            index += 1
          end
          n
        end

        def loadibe(index, bytesize)
          loadube(index, bytesize).extendsign(bytesize * BITS_PER_BYTE)
        end

        def loadule(index, bytesize)
          n = 0
          c = 0
          while bytesize > 0
            bytesize -= 1
            n |= getbyte(index) << (BITS_PER_BYTE * c)
            index += 1
            c += 1
          end
          n
        end

        def loadile(index, bytesize)
          loadule(index, bytesize).extendsign(bytesize * BITS_PER_BYTE)
        end

        def loadu8(index)
          getbyte(index.to_i)
        end

        def loadi8(index)
          loadu8(index).extendsign(8)
        end

        def loadu16be(index)
          (loadu8(index) << 8) | loadu8(index + 1)
        end

        def loadi16be(index)
          loadu16be(index).extendsign(16)
        end

        def loadu16le(index)
          loadu8(index) | (loadu8(index + 1) << 8)
        end

        def loadi16le(index)
          loadu16le(index).extendsign(16)
        end

        def loadu24be(index)
          (loadu8(index) << 16) | (loadu8(index + 1) << 8) | loadu8(index + 2)
        end

        def loadi24be(index)
          loadu24be(index).extendsign(24)
        end

        def loadu24le(index)
          loadu8(index) | (loadu8(index + 1) << 8) | (loadu8(index + 2) << 16)
        end

        def loadi24le(index)
          loadu24le(index).extendsign(24)
        end

        def loadu32be(index)
          (loadu8(index) << 24) | (loadu8(index + 1) << 16) | (loadu8(index + 2) << 8) | loadu8(index + 3)
        end

        def loadi32be(index)
          loadu32be(index).extendsign(32)
        end

        def loadu32le(index)
          loadu8(index) | (loadu8(index + 1) << 8) | (loadu8(index + 2) << 16) | (loadu8(index + 3) << 24)
        end

        def loadi32le(index)
          loadu32le(index).extendsign(32)
        end

        def loadu48be(index)
          (loadu24be(index) << 24) | loadu24be(index + 3)
        end

        def loadi48be(index)
          loadu48be(index).extendsign(48)
        end

        def loadu48le(index)
          loadu24le(index) | (loadu24le(index + 3) << 24)
        end

        def loadi48le(index)
          loadu48le(index).extendsign(48)
        end

        def loadu64be(index)
          (loadu32be(index) << 32) | loadu32be(index + 4)
        end

        def loadi64be(index)
          loadu64be(index).extendsign(64)
        end

        def loadu64le(index)
          loadu32le(index) | (loadu32le(index + 4) << 32)
        end

        def loadi64le(index)
          loadu64le(index).extendsign(64)
        end

        def loadf32be(index)
          unpack("@#{index.to_i}g")[0]
        end

        def loadf32le(index)
          unpack("@#{index.to_i}e")[0]
        end

        def loadf64be(index)
          unpack("@#{index.to_i}G")[0]
        end

        def loadf64le(index)
          unpack("@#{index.to_i}E")[0]
        end

        def store8(index, num)
          setbyte(index.to_i, num.to_i & 0xff)
        end

        def store16be(index, num)
          store8(index, num >> 8)
          store8(index + 1, num)
        end

        def store16le(index, num)
          store8(index, num)
          store8(index + 1, num >> 8)
        end

        def store24be(index, num)
          store8(index, num >> 16)
          store8(index + 1, num >> 8)
          store8(index + 2, num)
        end

        def store24le(index, num)
          store8(index, num)
          store8(index + 1, num >> 8)
          store8(index + 2, num >> 16)
        end

        def store32be(index, num)
          store8(index, num >> 24)
          store8(index + 1, num >> 16)
          store8(index + 2, num >> 8)
          store8(index + 3, num)
        end

        def store32le(index, num)
          store8(index, num)
          store8(index + 1, num >> 8)
          store8(index + 2, num >> 16)
          store8(index + 3, num >> 24)
        end

        def store48be(index, num)
          store24be(index, num >> 24)
          store24be(index + 3, num)
        end

        def store48le(index, num)
          store24le(index, num)
          store24le(index + 3, num >> 24)
        end

        def store64be(index, num)
          store32be(index, num >> 32)
          store32be(index + 4, num)
        end

        def store64le(index, num)
          store32le(index, num)
          store32le(index + 4, num >> 32)
        end

        def storef32be(index, num)
          setbinary(index, [num].pack("g"))
        end

        def storef32le(index, num)
          setbinary(index, [num].pack("e"))
        end

        def storef64be(index, num)
          setbinary(index, [num].pack("G"))
        end

        def storef64le(index, num)
          setbinary(index, [num].pack("E"))
        end

        #---
        ## native byte order operations
        #+++

        def loadf32(index)
          unpack("@#{index.to_i}f")[0]
        end

        def loadf64(index)
          unpack("@#{index.to_i}d")[0]
        end

        def storef32(index, num)
          setbinary(index, [num].pack("f"))
        end

        def storef64(index, num)
          setbinary(index, [num].pack("d"))
        end

        case "\0\1\2\3".unpack("I")[0]
        when 0x00010203 # big endian (network byte order)
          alias store storebe
          alias store16 store16be
          alias store24 store24be
          alias store32 store32be
          alias store48 store48be
          alias store64 store64be
          alias loadi loadibe
          alias loadi16 loadi16be
          alias loadi24 loadi24be
          alias loadi32 loadi32be
          alias loadi48 loadi48be
          alias loadi64 loadi64be
          alias loadu loadube
          alias loadu16 loadu16be
          alias loadu24 loadu24be
          alias loadu32 loadu32be
          alias loadu48 loadu48be
          alias loadu64 loadu64be

          alias storeswap storele
          alias store16swap store16le
          alias store24swap store24le
          alias store32swap store32le
          alias store48swap store48le
          alias store64swap store64le
          alias loadiswap loadile
          alias loadi16swap loadi16le
          alias loadi24swap loadi24le
          alias loadi32swap loadi32le
          alias loadi48swap loadi48le
          alias loadi64swap loadi64le
          alias loaduswap loadule
          alias loadu16swap loadu16le
          alias loadu24swap loadu24le
          alias loadu32swap loadu32le
          alias loadu48swap loadu48le
          alias loadu64swap loadu64le
          alias loadf32swap loadf32le
          alias loadf64swap loadf64le
        when 0x03020100 # little endian (vax byte order)
          alias store storele
          alias store16 store16le
          alias store24 store24le
          alias store32 store32le
          alias store48 store48le
          alias store64 store64le
          alias loadi loadile
          alias loadi16 loadi16le
          alias loadi24 loadi24le
          alias loadi32 loadi32le
          alias loadi48 loadi48le
          alias loadi64 loadi64le
          alias loadu loadule
          alias loadu16 loadu16le
          alias loadu24 loadu24le
          alias loadu32 loadu32le
          alias loadu48 loadu48le
          alias loadu64 loadu64le

          alias storeswap storebe
          alias store16swap store16be
          alias store24swap store24be
          alias store32swap store32be
          alias store48swap store48be
          alias store64swap store64be
          alias loadiswap loadibe
          alias loadi16swap loadi16be
          alias loadi24swap loadi24be
          alias loadi32swap loadi32be
          alias loadi48swap loadi48be
          alias loadi64swap loadi64be
          alias loaduswap loadube
          alias loadu16swap loadu16be
          alias loadu24swap loadu24be
          alias loadu32swap loadu32be
          alias loadu48swap loadu48be
          alias loadu64swap loadu64be
          alias loadf32swap loadf32be
          alias loadf64swap loadf64be
        else
          raise NotImplementedError
        end

        case TypeSpec::SIZEOF_SIZE_T
        when 4
          alias store_sizet store32
          alias load_sizet loadu32
          alias load_ssizet loadi32
        when 8
          alias store_sizet store64
          alias load_sizet loadu64
          alias load_ssizet loadi64
        else
          raise NotImplementedError
        end

        case TypeSpec::SIZEOF_LONG
        when 4
          alias store_long store32
          alias load_long loadi32
          alias load_ulong loadu32
        when 8
          alias store_long store64
          alias load_long loadi64
          alias load_ulong loadu64
        else
          raise NotImplementedError
        end
      end
    end

    class ::String
      extend Gogyou::Extensions::String
      include Gogyou::Extensions::String::Mixin
    end
  end
end
