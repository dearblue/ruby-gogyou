#vim: set fileencoding:utf-8

require "gogyou"

describe Gogyou do
  it "basic struct-1" do
    x = Gogyou.struct {
      uint32_t :a
    }

    expect(x.ancestors).to include Gogyou::Accessor::Struct
    expect(x::BYTESIZE).to eq 4
    expect(x::BYTEALIGN).to eq 4
  end

  it "basic struct-2" do
    x = Gogyou.struct {
      uint32_t :a, :b
    }

    expect(x.ancestors).to include Gogyou::Accessor::Struct
    expect(x::BYTESIZE).to eq 8
    expect(x::BYTEALIGN).to eq 4
  end
end

describe Gogyou::Model do
  it "struct in union" do
    x = Gogyou.union {
      struct {
        int32_t :a
      }
      uint32_t :b
    }

    reference = Gogyou::Model::Union[
      4, 4,
      Gogyou::Model::Field[0, :a, nil, Gogyou::Primitives::INT32_T],
      Gogyou::Model::Field[0, :b, nil, Gogyou::Primitives::UINT32_T]
    ]

    expect(x::MODEL).to eq reference
  end

  it "nested struct with anonymous fields" do
    x = Gogyou.struct {
      char :a
      union {
        int :b
        struct {
          int64_t :c
          int32_t :d
        }
      }
      char :e
    }

    ref = Gogyou::Model::Struct[
      32, 8,
      Gogyou::Model::Field[0, :a, nil, Gogyou::Primitives::CHAR],
      Gogyou::Model::Field[8, :b, nil, Gogyou::Primitives::INT],
      Gogyou::Model::Field[8, :c, nil, Gogyou::Primitives::INT64_T],
      Gogyou::Model::Field[16, :d, nil, Gogyou::Primitives::INT32_T],
      Gogyou::Model::Field[24, :e, nil, Gogyou::Primitives::CHAR]
    ]

    expect(x::MODEL).to eq ref
  end

  it "nested struct with array" do
    x = Gogyou.struct {
      char :a
      union {
        int :b
        struct -> {
          int64_t :c
          int32_t :d
        }, :e, 4
      }
    }

    ref = Gogyou::Model::Struct[
      72, 8,
      Gogyou::Model::Field[0, :a, nil, Gogyou::Primitives::CHAR],
      Gogyou::Model::Field[8, :b, nil, Gogyou::Primitives::INT],
      Gogyou::Model::Field[8, :e, [4], Gogyou::Model::Struct[
        16, 8,
        Gogyou::Model::Field[0, :c, nil, Gogyou::Primitives::INT64_T],
        Gogyou::Model::Field[8, :d, nil, Gogyou::Primitives::INT32_T]]]]
    expect(x::MODEL).to eq ref
  end

  it "nested struct in union" do
    x = Gogyou.struct {
      char :a
      union {
        int :b
        struct {
          int64_t :c
          int32_t :d
        }
      }
    }

    y = Gogyou.union {
      struct x, :a, :b
    }

    ref = Gogyou::Model::Union[
      24, 8,
      Gogyou::Model::Field[0, :a, nil, x],
      Gogyou::Model::Field[0, :b, nil, x]]
    expect(y::MODEL).to eq ref
  end
end

describe Gogyou::Accessor do
  it "fixed bytesize struct" do
    type = Gogyou.struct {
      char :a, 16
      int32_t :b
      int8_t :c
    }

    expect(type.bytesize).to eq 24
    expect(type.bytealign).to eq 4
    expect(type.extensible?).to eq false

    obj = type.bind((?a .. ?z).to_a.join)
    expect(obj.bytesize).to eq 24
    expect(obj.size).to eq 3
    expect(obj.a.bytesize).to eq 16
    expect(obj.a[1]).to eq ?b.ord
    expect(obj.a.to_s).to eq "abcdefghijklmnop"
  end

  it "extensibity struct" do
    type = Gogyou.struct {
      int32_t :a, :b, 2, 2
      int32_t :c, 4, 0
    }

    expect(type.bytesize).to eq 20
    expect(type.bytealign).to eq 4
    expect(type.extensible?).to eq true

    obj = type.new
    expect(obj.bytesize).to eq 20
  end

  it "extensibity struct in struct" do
    type = Gogyou.struct {
      struct -> {
        int32_t :a, :b, 2, 2
        int32_t :c, 4, 0
      }, :x
    }

    expect(type.bytesize).to eq 20
    expect(type.bytealign).to eq 4
    expect(type.extensible?).to eq true

    obj = type.new
    expect(obj.bytesize).to eq 20
  end

  it "packed struct" do
    type1 = Gogyou.struct {
      packed(1) {
        char :a
        int32_t :b
      }
    }

    expect(type1.bytesize).to eq 5
    expect(type1.bytealign).to eq 1
    expect(type1.extensible?).to eq false
    expect(type1.new.bytesize).to eq 5

    type2 = Gogyou.struct {
      packed(2) {
        char :a
        int32_t :b
      }
    }

    expect(type2.bytesize).to eq 6
    expect(type2.bytealign).to eq 2
    expect(type2.extensible?).to eq false
    expect(type2.new.bytesize).to eq 6
  end

  it "packed and nested struct" do
    type1 = Gogyou.struct {
      struct {
        packed(1) {
          char :a
          int32_t :b
        }
      }
    }

    expect(type1.bytesize).to eq 5
    expect(type1.bytealign).to eq 1
    expect(type1.extensible?).to eq false
    expect(type1.new.bytesize).to eq 5

    type2 = Gogyou.struct {
      packed(1) {
        struct {
          char :a
          int32_t :b
        }
      }
    }

    expect(type2.bytesize).to eq 5
    expect(type2.bytealign).to eq 1
    expect(type2.extensible?).to eq false
    expect(type2.new.bytesize).to eq 5

    type3 = Gogyou.struct {
      packed(1) {
        struct -> {
          char :a
          int32_t :b
        }, :x
      }
    }

    expect(type3.bytesize).to eq 5
    expect(type3.bytealign).to eq 1
    expect(type3.extensible?).to eq false
    expect(type3.new.bytesize).to eq 5
  end

  it "packed and nested struct" do
    type1 = Gogyou.struct {
      packed(2) {
        struct {
          packed(1) {
            char :a
            int32_t :b
          }
        }
      }
    }

    expect(type1.bytesize).to eq 6
    expect(type1.bytealign).to eq 2
    expect(type1.extensible?).to eq false
    expect(type1.new.bytesize).to eq 6

    expect {
      Gogyou.struct {
        packed(1) {
          packed(2) {
            struct {
              char :a
              int32_t :b
            }
          }
        }
      }
    }.to raise_error RuntimeError
  end
end

describe "user typeinfo" do
  it "definition and use" do
    x1 = Object.new
    Gogyou.define_typeinfo(x1, 8.0, Rational(5, 2), false,
                           ->(buffer, offset) { buffer.byteslice(offset, 8) },
                           ->(buffer, offset, value) { buffer.setbinary(offset, value, 0, 16) })
    expect(x1.bytesize).to eq 8
    expect(x1.bytealign).to eq 2
    expect(x1.extensible?).to eq false

    x2 = Object.new
    Gogyou.define_typeinfo(x2, "16", "4", "false",
                           "buffer.byteslice(offset, 16)",
                           "buffer.setbinary(offset, value.downcase, 0, 16)")
    expect(x2.bytesize).to eq 16
    expect(x2.bytealign).to eq 4
    expect(x2.extensible?).to eq false

    type = Gogyou.struct {
      struct x1, :a
      struct x2, :b
    }

    expect(type.bytesize).to eq 24
    expect(type.bytealign).to eq 4
    expect(type.extensible?).to eq false

    v = type.bind("abcdefghijklmnopqrstuvwx")
    expect(v.bytesize).to eq 24
    expect(v.size).to eq 2
    expect(v.a).to eq "abcdefgh"
    v.a = "ABCDEFGH"
    expect(v.buffer).to eq "ABCDEFGHijklmnopqrstuvwx"
    expect(v.b).to eq "ijklmnopqrstuvwx"
    v.b = "0ijklmnopqrstuv9wx"
    expect(v.buffer).to eq "ABCDEFGH0ijklmnopqrstuv9"
  end
end
