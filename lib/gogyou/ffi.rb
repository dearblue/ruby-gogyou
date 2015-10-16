require "ffi"
require_relative "../gogyou"

module Gogyou
  module Extensions
    module FFI
      module AbstractMemory
        def to_address
          to_i
        end

        alias to_ptr to_address

        def bytesize
          size
        end

        def setbinary(index, mem, offset = 0, size = mem.bytesize - offset)
          offset = offset.to_i
          size = size.to_i
          size1 = mem.bytesize - offset
          size = size1 if size > size1

          if size > 0
            put_bytes(index, mem.byteslice(offset, size))
          end

          self
        end

        def byteslice(index, size)
          get_bytes(index, size)
        end

        def setbyte(o, n)
          set_uint8(o, n)
        end

        def getbyte(o)
          get_uint8(o)
        end
      end
    end
  end
end

module FFI
  class AbstractMemory
    include Gogyou::Extensions::FFI::AbstractMemory
    include Gogyou::Extensions::ByteArray
  end
end
