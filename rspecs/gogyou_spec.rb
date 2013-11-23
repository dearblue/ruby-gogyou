#!/usr/bin/env ruby
#vim: set fileencoding:utf-8

require "gogyou"

describe Gogyou do
  before :all do
    Type1 = Gogyou.struct do
      uint32_t :data1    
      int16_t  :data2, 2 
      uint64_t :data3    
      uint8_t  :data4, 2 
      char     :data5, 2 
      ustring  :data6, 4 
      binary   :data7, 8 
    end
  end

  it "Type1::PACK_FORMAT" do
    Type1::PACK_FORMAT.should ==
      "#{Gogyou::Types::FORMATOF_UINT32_T}s2#{Gogyou::Types::FORMATOF_UINT64_T}C2c2Z4a8"
  end

  it "Type1::SIZE" do
    Type1::SIZE.should == 32
  end

  it "Type1.alloc" do
    Type1.alloc.to_a.should ==
      [0, [0, 0], 0, [0, 0], [0, 0], "", "\0\0\0\0\0\0\0\0"]
  end

  it "Type1.unpack" do
    Type1.unpack("0123456789abcdef0123456789abcdef").to_a.should ==
      [858927408, [13620, 14134], 7378413942531504440, [48, 49], [50, 51], "4567", "89abcdef"]
  end
end

describe Gogyou do
  before :all do
    Type2 = Gogyou.struct do
      padding 1
      uint32_t :data1    
      padding 1
      int16_t  :data2, 2 
      padding 1
      uint64_t :data3    
      padding 1
      uint8_t  :data4, 2 
      padding 1
      char     :data5, 2 
      padding 1
      ustring  :data6, 4 
      padding 1
      binary   :data7, 8 
    end
  end

  it "Type2::PACK_FORMAT" do
    Type2::PACK_FORMAT.should ==
      "xx3#{Gogyou::Types::FORMATOF_UINT32_T}xxs2xx#{Gogyou::Types::FORMATOF_UINT64_T}xC2xc2xZ4xa8"
  end

  it "Type2::SIZE" do
    Type2::SIZE.should == 44
  end

  it "Type2.alloc" do
    Type2.alloc.to_a.should ==
      [0, [0, 0], 0, [0, 0], [0, 0], "", "\0\0\0\0\0\0\0\0"]
  end

  it "Type2.unpack" do
    Type2.unpack("0123456789abcdef0123456789abcdef0123456789abcdef").to_a.should ==
      [926299444, [25185, 25699], 3978425819141910832, [57, 97], [99, 100], "f012", "456789ab"]
  end
end
