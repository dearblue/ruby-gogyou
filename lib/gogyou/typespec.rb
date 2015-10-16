module Gogyou
  module TypeSpec
    SIZEOF_CHAR     = [0].pack("C").bytesize
    SIZEOF_SHORT    = [0].pack("S!").bytesize
    SIZEOF_INT      = [0].pack("I!").bytesize
    SIZEOF_LONG     = [0].pack("L!").bytesize
    SIZEOF_LONGLONG = [0].pack("Q").bytesize
    SIZEOF_SIZE_T   = [nil].pack("P").bytesize
    SIZEOF_FLOAT    = [0].pack("F").bytesize
    SIZEOF_DOUBLE   = [0].pack("D").bytesize
    SIZEOF_INTPTR_T = SIZEOF_UINTPTR_T = SIZEOF_SIZE_T
  end

  include TypeSpec
end
