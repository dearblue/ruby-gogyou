require "fiddle"
require_relative "../gogyou"

module Gogyou
  module Extensions
    module Fiddle
      module Pointer
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
            self[index, size] = mem.byteslice(offset, size)
          end

          self
        end

        def byteslice(index, size)
          return nil unless index < bytesize
          self[index, size]
        end

        def setbyte(o, n)
          self[o] = 0xff & n.to_i
        end

        def getbyte(o)
          0xff & self[o]
        end
      end
    end
  end
end

module Fiddle
  class Pointer
    include Gogyou::Extensions::Fiddle::Pointer
    include Gogyou::Extensions::ByteArray
  end
end
