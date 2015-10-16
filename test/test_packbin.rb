#!ruby

require "test-unit"
require "gogyou"

class TestBinaryPacker < Test::Unit::TestCase
  def test_pack_binary16
    assert_equal 0x0000, 0.0.pack_binary16
    assert_equal 0x8000, -0.0.pack_binary16
    assert_equal 0x3800, 0.5.pack_binary16
    assert_equal 0x3c00, 1.0.pack_binary16
    assert_equal 0x4000, 2.0.pack_binary16
    assert_equal 0x7c00, (+Float::INFINITY).pack_binary16
    assert_equal 0xfc00, (-Float::INFINITY).pack_binary16
    assert_equal 0x7e00, Float::NAN.pack_binary16
    assert_equal 0x7c00, 65536.pack_binary16 # infinity
  end

  def test_unpack_binary16
    assert_equal +Float::INFINITY, 0x7c00.unpack_binary16
    assert_equal -Float::INFINITY, 0xfc00.unpack_binary16
    assert_equal "NaN", 0x7e00.unpack_binary16.to_s
    assert_equal "NaN", 0xfe00.unpack_binary16.to_s
    assert_equal "-0.0", 0x8000.unpack_binary16.to_s
    assert_equal 0.0, 0x0000.unpack_binary16
    assert_equal 0.5, 0x3800.unpack_binary16
    assert_equal 1.0, 0x3c00.unpack_binary16
    assert_equal 2.0, 0x4000.unpack_binary16
    assert_equal 0x07ff / 0x0400.to_f, 0x3fff.unpack_binary16
  end

  def test_unpack_binary32
    assert_equal +Float::INFINITY, 0x7f800000.unpack_binary32
    assert_equal -Float::INFINITY, 0xff800000.unpack_binary32
    assert_equal "NaN", 0x7fc00000.unpack_binary32.to_s
    assert_equal "NaN", 0xffc00000.unpack_binary32.to_s
    assert_equal "-0.0", 0x80000000.unpack_binary32.to_s
    assert_equal 0.0, 0x00000000.unpack_binary32
    assert_equal 0.5, 0x3f000000.unpack_binary32
    assert_equal 1.0, 0x3f800000.unpack_binary32
    assert_equal 2.0, 0x40000000.unpack_binary32
    assert_equal 0x00ffffff / 0x00800000.to_f, 0x3fffffff.unpack_binary32
  end

  def test_unpack_binary64
    assert_equal +Float::INFINITY, 0x7ff0000000000000.unpack_binary64
    assert_equal -Float::INFINITY, 0xfff0000000000000.unpack_binary64
    assert_equal "NaN", 0x7ff8000000000000.unpack_binary64.to_s
    assert_equal "NaN", 0xfff8000000000000.unpack_binary64.to_s
    assert_equal "-0.0", 0x8000000000000000.unpack_binary64.to_s
    assert_equal 0.0, 0x0000000000000000.unpack_binary64
    assert_equal 0.5, 0x3fe0000000000000.unpack_binary64
    assert_equal 1.0, 0x3ff0000000000000.unpack_binary64
    assert_equal 2.0, 0x4000000000000000.unpack_binary64
  end

  def test_pack_and_unpack_32
    200.times do
      n = [rand].pack("g").unpack("g")[0]
      assert_equal n, [n].pack("g").unpack("N")[0].unpack_binary32
      n = [1 / n].pack("g").unpack("g")[0]
      assert_equal n, [n].pack("g").unpack("N")[0].unpack_binary32
    end
  end
end
