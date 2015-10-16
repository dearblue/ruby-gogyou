module Gogyou
  module Extensions
    #
    # .bytesize・.byteslice・.setbinary・.getbyte・.setbyte メソッドを用いて
    # 整数値・実数値を埋め込む・取り出すメソッドを定義します。
    #
    # gogyou は ruby の String や Fiddle::Pointer、FFI::AbstractPointer
    # クラスにこのモジュールを include しています。
    #
    module ByteArray
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
          index + bytesize <= bytesize() &&
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
                                index < bytesize() &&
                                index + bytesize <= bytesize() &&
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

      def store8(index, num)
        setbyte(index.to_i, 0xff & num.to_i)
      end

      def loadu8(index)
        getbyte(index)
      end

      def loadi8(index)
        getbyte(index).extendsign_char
      end

      def store16(index, num)
        setbinary(index, [num].pack("S"))
      end

      def loadi16(index)
        byteslice(index, 2).unpack("s")[0]
      end

      def loadu16(index)
        byteslice(index, 2).unpack("S")[0]
      end

      def store16swap(index, num)
        setbinary(index, [num.swap16].pack("S"))
      end

      def loadi16swap(index)
        byteslice(index, 2).unpack("s")[0].swap16s
      end

      def loadu16swap(index)
        byteslice(index, 2).unpack("S")[0].swap16
      end

      def store16be(index, num)
        index = index.to_i
        num = 0xffff & num.to_i
        setbyte(index    , num >>  8)
        setbyte(index + 1, num      )
      end

      def loadu16be(index)
        (getbyte(index) << 8) |
          (getbyte(index + 1))
      end

      def loadi16be(index)
        (getbyte(index).extendsign_char << 8) |
          (getbyte(index + 1))
      end

      def store16le(index, num)
        index = index.to_i
        num = 0xffff & num.to_i
        setbyte(index    , num      )
        setbyte(index + 1, num >>  8)
      end

      def loadu16le(index)
        (getbyte(index)) |
          (getbyte(index + 1) << 8)
      end

      def loadi16le(index)
        (getbyte(index)) |
          (getbyte(index + 1).extendsign_char << 8)
      end

      def store24be(index, num)
        index = index.to_i
        num = 0xffffff & num.to_i
        setbyte(index    , num >> 16)
        setbyte(index + 1, num >>  8)
        setbyte(index + 2, num      )
      end

      def loadu24be(index)
        (getbyte(index) << 16) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2))
      end

      def loadi24be(index)
        (getbyte(index).extendsign_char << 16) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2))
      end

      def store24le(index, num)
        index = index.to_i
        num = 0xffffff & num.to_i
        setbyte(index    , num      )
        setbyte(index + 1, num >>  8)
        setbyte(index + 2, num >> 16)
      end

      def loadu24le(index)
        (getbyte(index)) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2) << 16)
      end

      def loadi24le(index)
        (getbyte(index)) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2).extendsign_char << 16)
      end

      def store32(index, num)
        setbinary(index, [num].pack("L"))
      end

      def loadi32(index)
        byteslice(index, 4).unpack("l")[0]
      end

      def loadu32(index)
        byteslice(index, 4).unpack("L")[0]
      end

      def store32swap(index, num)
        setbinary(index, [num.swap32].pack("L"))
      end

      def loadi32swap(index)
        byteslice(index, 4).unpack("l")[0].swap32s
      end

      def loadu32swap(index)
        byteslice(index, 4).unpack("L")[0].swap32
      end

      def store32be(index, num)
        index = index.to_i
        num = 0xffffffff & num.to_i
        setbyte(index    , num >> 24)
        setbyte(index + 1, num >> 16)
        setbyte(index + 2, num >>  8)
        setbyte(index + 3, num & 0xff)
      end

      def loadu32be(index)
        (getbyte(index) << 24) |
          (getbyte(index + 1) << 16) |
          (getbyte(index + 2) << 8) |
          (getbyte(index + 3))
      end

      def loadi32be(index)
        (getbyte(index).extendsign_char << 24) |
          (getbyte(index + 1) << 16) |
          (getbyte(index + 2) << 8) |
          (getbyte(index + 3))
      end

      def store32le(index, num)
        index = index.to_i
        num = 0xffffffff & num.to_i
        setbyte(index    , num & 0xff)
        setbyte(index + 1, num >>  8)
        setbyte(index + 2, num >> 16)
        setbyte(index + 3, num >> 24)
      end

      def loadu32le(index)
        (getbyte(index)) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2) << 16) |
          (getbyte(index + 3) << 24)
      end

      def loadi32le(index)
        (getbyte(index)) |
          (getbyte(index + 1) << 8) |
          (getbyte(index + 2) << 16) |
          (getbyte(index + 3).extendsign_char << 24)
      end

      def store48be(index, num)
        num = num.to_i
        store24be(index    , num >> 24)
        store24be(index + 3, num      )
      end

      def loadu48be(index)
        (loadu24be(index) << 24) | loadu24be(index + 3)
      end

      def loadi48be(index)
        (loadi24be(index) << 24) | loadu24be(index + 3)
      end

      def store48le(index, num)
        num = num.to_i
        store24le(index    , num      )
        store24le(index + 3, num >> 24)
      end

      def loadu48le(index)
        loadu24le(index) | (loadu24le(index + 3) << 24)
      end

      def loadi48le(index)
        loadu24le(index) | (loadi24le(index + 3) << 24)
      end

      def store64(index, num)
        setbinary(index, [num].pack("Q"))
      end

      def loadi64(index)
        byteslice(index, 8).unpack("q")[0]
      end

      def loadu64(index)
        byteslice(index, 8).unpack("Q")[0]
      end

      def store64swap(index, num)
        setbinary(index, [num.swap64].pack("Q"))
      end

      def loadi64swap(index)
        byteslice(index, 8).unpack("q")[0].swap64s
      end

      def loadu64swap(index)
        byteslice(index, 8).unpack("Q")[0].swap64
      end

      def store64be(index, num)
        num = num.to_i
        store32be(index    , num >> 32)
        store32be(index + 4, num      )
      end

      def loadu64be(index)
        (loadu32be(index) << 32) | loadu32be(index + 4)
      end

      def loadi64be(index)
        (loadi32be(index) << 32) | loadu32be(index + 4)
      end

      def store64le(index, num)
        num = num.to_i
        store32le(index    , num      )
        store32le(index + 4, num >> 32)
      end

      def loadu64le(index)
        loadu32le(index) | (loadu32le(index + 4) << 32)
      end

      def loadi64le(index)
        loadu32le(index) | (loadi32le(index + 4) << 32)
      end

      def storef16(index, num)
        store16(index, num.pack_binary16)
      end

      def loadf16(index)
        loadu16(index).unpack_binary16
      end

      def storef16swap(index, num)
        store16swap(index, num.pack_binary16)
      end

      def loadf16swap(index)
        loadu16swap(index).unpack_binary16
      end

      def storef16be(index, num)
        store16be(index, num.pack_binary16)
      end

      def loadf16be(index)
        loadu16be(index).unpack_binary16
      end

      def storef16le(index, num)
        store16le(index, num.pack_binary16)
      end

      def loadf16le(index)
        loadu16le(index).unpack_binary16
      end

      def storef32(index, num)
        store32(index, num.pack_binary32)
      end

      def loadf32(index)
        loadu32(index).unpack_binary32
      end

      def storef32swap(index, num)
        store32swap(index, num.pack_binary32)
      end

      def loadf32swap(index)
        loadu32swap(index).unpack_binary32
      end

      def storef32be(index, num)
        store32be(index, num.pack_binary32)
      end

      def loadf32be(index)
        loadu32be(index).unpack_binary32
      end

      def storef32le(index, num)
        store32le(index, num.pack_binary32)
      end

      def loadf32le(index)
        loadu32le(index).unpack_binary32
      end

      def storef64(index, num)
        store64(index, num.pack_binary64)
      end

      def loadf64(index)
        loadu64(index).unpack_binary64
      end

      def storef64swap(index, num)
        store64swap(index, num.pack_binary64)
      end

      def loadf64swap(index)
        loadu64swap(index).unpack_binary64
      end

      def storef64be(index, num)
        store64be(index, num.pack_binary64)
      end

      def loadf64be(index)
        loadu64be(index).unpack_binary64
      end

      def storef64le(index, num)
        store64le(index, num.pack_binary64)
      end

      def loadf64le(index)
        loadu64le(index).unpack_binary64
      end

      def store16q8(index, num)
        store16(index, num * 256)
      end

      def loadi16q8(index)
        loadi16(index) / 256.0
      end

      def loadu16q8(index)
        loadu16(index) / 256.0
      end

      def store16q8swap(index, num)
        store16swap(index, num * 256)
      end

      def loadi16q8swap(index)
        loadi16swap(index) / 256.0
      end

      def loadu16q8swap(index)
        loadu16swap(index) / 256.0
      end

      def store16q8be(index, num)
        store16be(index, num * 256)
      end

      def loadi16q8be(index)
        loadi16be(index) / 256.0
      end

      def loadu16q8be(index)
        loadu16be(index) / 256.0
      end

      def store16q8le(index, num)
        store16le(index, num * 256)
      end

      def loadi16q8le(index)
        loadi16le(index) / 256.0
      end

      def loadu16q8le(index)
        loadu16le(index) / 256.0
      end

      def store32q6(index, num)
        store32(index, num * 64)
      end

      def loadi32q6(index)
        loadi32(index) / 64.0
      end

      def loadu32q6(index)
        loadu32(index) / 64.0
      end

      def store32q6swap(index, num)
        store32swap(index, num * 64)
      end

      def loadi32q6swap(index)
        loadi32swap(index) / 64.0
      end

      def loadu32q6swap(index)
        loadu32swap(index) / 64.0
      end

      def store32q6be(index, num)
        store32be(index, num * 64)
      end

      def loadi32q6be(index)
        loadi32be(index) / 64.0
      end

      def loadu32q6be(index)
        loadu32be(index) / 64.0
      end

      def store32q6le(index, num)
        store32le(index, num * 64)
      end

      def loadi32q6le(index)
        loadi32le(index) / 64.0
      end

      def loadu32q6le(index)
        loadu32le(index) / 64.0
      end

      def store32q8(index, num)
        store32(index, num * 256)
      end

      def loadi32q8(index)
        loadi32(index) / 256.0
      end

      def loadu32q8(index)
        loadu32(index) / 256.0
      end

      def store32q8swap(index, num)
        store32swap(index, num * 256)
      end

      def loadi32q8swap(index)
        loadi32swap(index) / 256.0
      end

      def loadu32q8swap(index)
        loadu32swap(index) / 256.0
      end

      def store32q8be(index, num)
        store32be(index, num * 256)
      end

      def loadi32q8be(index)
        loadi32be(index) / 256.0
      end

      def loadu32q8be(index)
        loadu32be(index) / 256.0
      end

      def store32q8le(index, num)
        store32le(index, num * 256)
      end

      def loadi32q8le(index)
        loadi32le(index) / 256.0
      end

      def loadu32q8le(index)
        loadu32le(index) / 256.0
      end

      def store32q12(index, num)
        store32(index, num * 4096)
      end

      def loadi32q12(index)
        loadi32(index) / 4096.0
      end

      def loadu32q12(index)
        loadu32(index) / 4096.0
      end

      def store32q12swap(index, num)
        store32swap(index, num * 4096)
      end

      def loadi32q12swap(index)
        loadi32swap(index) / 4096.0
      end

      def loadu32q12swap(index)
        loadu32swap(index) / 4096.0
      end

      def store32q12be(index, num)
        store32be(index, num * 4096)
      end

      def loadi32q12be(index)
        loadi32be(index) / 4096.0
      end

      def loadu32q12be(index)
        loadu32be(index) / 4096.0
      end

      def store32q12le(index, num)
        store32le(index, num * 4096)
      end

      def loadi32q12le(index)
        loadi32le(index) / 4096.0
      end

      def loadu32q12le(index)
        loadu32le(index) / 4096.0
      end

      def store32q16(index, num)
        store32(index, num * 65536)
      end

      def loadi32q16(index)
        loadi32(index) / 65536.0
      end

      def loadu32q16(index)
        loadu32(index) / 65536.0
      end

      def store32q16swap(index, num)
        store32swap(index, num * 65536)
      end

      def loadi32q16swap(index)
        loadi32swap(index) / 65536.0
      end

      def loadu32q16swap(index)
        loadu32swap(index) / 65536.0
      end

      def store32q16be(index, num)
        store32be(index, num * 65536)
      end

      def loadi32q16be(index)
        loadi32be(index) / 65536.0
      end

      def loadu32q16be(index)
        loadu32be(index) / 65536.0
      end

      def store32q16le(index, num)
        store32le(index, num * 65536)
      end

      def loadi32q16le(index)
        loadi32le(index) / 65536.0
      end

      def loadu32q16le(index)
        loadu32le(index) / 65536.0
      end

      def store32q24(index, num)
        store32(index, num * 16777216)
      end

      def loadi32q24(index)
        loadi32(index) / 16777216.0
      end

      def loadu32q24(index)
        loadu32(index) / 16777216.0
      end

      def store32q24swap(index, num)
        store32swap(index, num * 16777216)
      end

      def loadi32q24swap(index)
        loadi32swap(index) / 16777216.0
      end

      def loadu32q24swap(index)
        loadu32swap(index) / 16777216.0
      end

      def store32q24be(index, num)
        store32be(index, num * 16777216)
      end

      def loadi32q24be(index)
        loadi32be(index) / 16777216.0
      end

      def loadu32q24be(index)
        loadu32be(index) / 16777216.0
      end

      def store32q24le(index, num)
        store32le(index, num * 16777216)
      end

      def loadi32q24le(index)
        loadi32le(index) / 16777216.0
      end

      def loadu32q24le(index)
        loadu32le(index) / 16777216.0
      end


      def store_char(index, num)
        setbinary(index, [num].pack("S!"))
      end

      def load_char(index)
        byteslice(index, TypeSpec::SIZEOF_CHAR).unpack("c!")[0]
      end

      def load_uchar(index)
        byteslice(index, TypeSpec::SIZEOF_CHAR).unpack("C!")[0]
      end

      def store_short(index, num)
        setbinary(index, [num].pack("S!"))
      end

      def load_short(index)
        byteslice(index, TypeSpec::SIZEOF_SHORT).unpack("s!")[0]
      end

      def load_ushort(index)
        byteslice(index, TypeSpec::SIZEOF_SHORT).unpack("S!")[0]
      end

      def store_int(index, num)
        setbinary(index, [num].pack("I!"))
      end

      def load_int(index)
        byteslice(index, TypeSpec::SIZEOF_INT).unpack("i!")[0]
      end

      def load_uint(index)
        byteslice(index, TypeSpec::SIZEOF_INT).unpack("I!")[0]
      end

      def store_long(index, num)
        setbinary(index, [num].pack("L!"))
      end

      def load_long(index)
        byteslice(index, TypeSpec::SIZEOF_LONG).unpack("l!")[0]
      end

      def load_ulong(index)
        byteslice(index, TypeSpec::SIZEOF_LONG).unpack("L!")[0]
      end

      def store_longlong(index, num)
        setbinary(index, [num].pack("Q"))
      end

      def load_longlong(index)
        byteslice(index, TypeSpec::SIZEOF_LONGLONG).unpack("q")[0]
      end

      def load_ulonglong(index)
        byteslice(index, TypeSpec::SIZEOF_LONGLONG).unpack("Q")[0]
      end

      def store_float(index, num)
        setbinary(index, [num].pack("f"))
      end

      def load_float(index)
        byteslice(index, TypeSpec::SIZEOF_FLOAT).unpack("f")[0]
      end

      def store_double(index, num)
        setbinary(index, [num].pack("d"))
      end

      def load_double(index)
        byteslice(index, TypeSpec::SIZEOF_DOUBLE).unpack("d")[0]
      end


      case "\0\1\2\3".unpack("I")[0]
      when 0x00010203 # big endian (network byte order)
        alias store storebe
        alias loadi loadibe
        alias loadu loadube

        alias storeswap storele
        alias loadiswap loadile
        alias loaduswap loadule
      when 0x03020100 # little endian (vax byte order)
        alias store storele
        alias loadi loadile
        alias loadu loadule

        alias storeswap storebe
        alias loadiswap loadibe
        alias loaduswap loadube
      else
        # any byte order...
      end

      case TypeSpec::SIZEOF_SIZE_T
      when TypeSpec::SIZEOF_LONGLONG
        alias store_sizet store_longlong
        alias load_sizet load_ulonglong
        alias load_ssizet load_longlong
      when TypeSpec::SIZEOF_LONG
        alias store_sizet store_long
        alias load_sizet load_ulong
        alias load_ssizet load_long
      when TypeSpec::SIZEOF_INT
        alias store_sizet store_int
        alias load_sizet load_uint
        alias load_ssizet load_int
      else
        def store_sizet(o, v)
          raise NotImplementedError, "unsupported system (expected sizeof(void *) to 4 or 8, but #{TypeSpec::SIZEOF_SIZE_T})"
        end

        def load_ssizet(o)
          raise NotImplementedError, "unsupported system (expected sizeof(void *) to 4 or 8, but #{TypeSpec::SIZEOF_SIZE_T})"
        end

        def load_sizet(o)
          raise NotImplementedError, "unsupported system (expected sizeof(void *) to 4 or 8, but #{TypeSpec::SIZEOF_SIZE_T})"
        end
      end
    end
  end
end
