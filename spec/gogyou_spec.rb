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
      Gogyou::Model::Field[0, :a, nil, Gogyou::Primitives::INT32_T, 0x00],
      Gogyou::Model::Field[0, :b, nil, Gogyou::Primitives::UINT32_T, 0x00]
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
      Gogyou::Model::Field[0, :a, nil, Gogyou::Primitives::CHAR, 0],
      Gogyou::Model::Field[8, :b, nil, Gogyou::Primitives::INT, 0],
      Gogyou::Model::Field[8, :c, nil, Gogyou::Primitives::INT64_T, 0],
      Gogyou::Model::Field[16, :d, nil, Gogyou::Primitives::INT32_T, 0],
      Gogyou::Model::Field[24, :e, nil, Gogyou::Primitives::CHAR, 0]
    ]

    expect(x::MODEL).to eq ref
  end
end

describe Gogyou::Accessor do
  it "fixed bytesize struct" do
    type = Gogyou.struct {
      int32_t :a, :b, 2, 2
    }

    expect(type.bytesize).to eq 20
    expect(type.bytealign).to eq 4
    expect(type.extensible?).to eq false

    obj = type.new
    expect(obj.bytesize).to eq 20
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
end
