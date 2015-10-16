#!ruby

require "test-unit"
require "gogyou"

class TestLoadStore < Test::Unit::TestCase
  @@str = [0, 0, 0, 0, 0, 0, 0, 0, 160, 164, 221, 186, 248, 213, 191, 215, 137, 242, 225, 169, 153, 224, 148, 134].pack("C*")

  def test_load
    16.times do |i|
      assert_equal @@str.unpack("@#{i}C")[0], @@str.loadu8(i)
      assert_equal @@str.unpack("@#{i}S")[0], @@str.loadu16(i)
      assert_equal @@str.unpack("@#{i}L")[0], @@str.loadu32(i)
      assert_equal @@str.unpack("@#{i}Q")[0], @@str.loadu64(i)
      assert_equal @@str.unpack("@#{i}c")[0], @@str.loadi8(i)
      assert_equal @@str.unpack("@#{i}s")[0], @@str.loadi16(i)
      assert_equal @@str.unpack("@#{i}l")[0], @@str.loadi32(i)
      assert_equal @@str.unpack("@#{i}q")[0], @@str.loadi64(i)
      assert_equal @@str.unpack("@#{i}s!")[0], @@str.load_short(i)
      assert_equal @@str.unpack("@#{i}i!")[0], @@str.load_int(i)
      assert_equal @@str.unpack("@#{i}l!")[0], @@str.load_long(i)
      assert_equal @@str.unpack("@#{i}q")[0], @@str.load_longlong(i)
      assert_equal @@str.unpack("@#{i}S!")[0], @@str.load_ushort(i)
      assert_equal @@str.unpack("@#{i}I!")[0], @@str.load_uint(i)
      assert_equal @@str.unpack("@#{i}L!")[0], @@str.load_ulong(i)
      assert_equal @@str.unpack("@#{i}Q")[0], @@str.load_ulonglong(i)
      assert_equal @@str.unpack("@#{i}f")[0], @@str.loadf32(i)
      assert_equal @@str.unpack("@#{i}d")[0], @@str.loadf64(i)
      assert_equal @@str.unpack("@#{i}n")[0].unpack_binary16, @@str.loadf16be(i)
      assert_equal @@str.unpack("@#{i}N")[0].unpack_binary32, @@str.loadf32be(i)
      assert_equal @@str.unpack("@#{i}Q>")[0].unpack_binary64, @@str.loadf64be(i)
      assert_equal @@str.unpack("@#{i}v")[0].unpack_binary16, @@str.loadf16le(i)
      assert_equal @@str.unpack("@#{i}V")[0].unpack_binary32, @@str.loadf32le(i)
      assert_equal @@str.unpack("@#{i}Q<")[0].unpack_binary64, @@str.loadf64le(i)
    end
  end
end

class TestSwap < Test::Unit::TestCase
  def test_swap
    assert_equal 0x0011, 0x1100.swap16
    assert_equal 0x001122, 0x221100.swap24
    assert_equal 0x00112233, 0x33221100.swap32
    assert_equal 0x001122334455, 0x554433221100.swap48
    assert_equal 0x0011223344556677, 0x7766554433221100.swap64

    assert_equal 0xffee, 0xeeff.swap16
    assert_equal 0xffeedd, 0xddeeff.swap24
    assert_equal 0xffeeddcc, 0xccddeeff.swap32
    assert_equal 0xffeeddccbbaa, 0xaabbccddeeff.swap48
    assert_equal 0xffeeddccbbaa9988, 0x8899aabbccddeeff.swap64

    assert_equal 0x0011, 0x1100.swap16s
    assert_equal 0x001122, 0x221100.swap24s
    assert_equal 0x00112233, 0x33221100.swap32s
    assert_equal 0x001122334455, 0x554433221100.swap48s
    assert_equal 0x0011223344556677, 0x7766554433221100.swap64s

    assert_equal ~0x0011, 0xeeff.swap16s
    assert_equal ~0x001122, 0xddeeff.swap24s
    assert_equal ~0x00112233, 0xccddeeff.swap32s
    assert_equal ~0x001122334455, 0xaabbccddeeff.swap48s
    assert_equal ~0x0011223344556677, 0x8899aabbccddeeff.swap64s
  end
end
