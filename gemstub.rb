
# "lib/gogyou/primitives.rb" がない場合は、読み込みを遅らせる。Gogyou::VERSION の参照も後回し。
hasprims = File.file?(File.join(File.dirname(__FILE__), "lib", "gogyou", "primitives.rb"))
require_relative "lib/gogyou" if hasprims

GEMSTUB = Gem::Specification.new do |s|
  s.name = "gogyou"
  s.version = Gogyou::VERSION if hasprims
  s.summary = "binary data operation library with the C liked struct and union"
  s.description = <<EOS
The gogyou is a library that provides auxiliary features of binary data operation for ruby.

The C-liked struct, union and multidimensional array definition are posible in ruby syntax.

* Usable nested struct.
* Usable nested union.
* Usable multidimensional array.
* Usable user definition types.
EOS
  s.license = "2-clause BSD License"
  s.author = "dearblue"
  s.email = "dearblue@users.sourceforge.jp"
  #s.author = "**PRIVATE**"
  #s.email = "**PRIVATE**"
  s.homepage = "http://sourceforge.jp/projects/rutsubo/"

  s.required_ruby_version = ">= 2.0"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "rake", "~> 10.0"
end

LIB << "lib/gogyou/primitives.rb"
EXTRA << "mkprims.rb"
CLEAN << "lib/gogyou/primitives.rb"

file "lib/gogyou/primitives.rb" => "mkprims.rb" do
  sh "ruby mkprims.rb"
  require_relative "lib/gogyou"
  GEMSTUB.version = Gogyou::VERSION
end
