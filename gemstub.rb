
require_relative "lib/gogyou/version"

GEMSTUB = Gem::Specification.new do |s|
  s.name = "gogyou"
  s.version = Gogyou::VERSION
  s.summary = "binary data operation library with the C liked struct and union"
  s.description = <<EOS
The gogyou is a library written at pure ruby that provides auxiliary features of binary data operation for ruby.

The C-liked struct, union and multidimensional array definition are posible in ruby syntax.

* Available nested struct and union with anonymous field.
* Available multidimensional array.
* Available const field.
* Available packed field.
* Available user definition types.
EOS
  s.license = "2-clause BSD License"
  s.author = "dearblue"
  s.email = "dearblue@users.osdn.me"
  s.homepage = "https://osdn.jp/projects/rutsubo/"

  s.required_ruby_version = ">= 2.0"
  s.add_development_dependency "rspec", "~> 2.14"
  s.add_development_dependency "rake", "~> 10.0"
end

primitives = "lib/gogyou/primitives.rb"
mkprims = "mkprims.rb"
LIB << primitives
CLEAN << primitives
EXTRA << mkprims

file primitives => mkprims do
  sh "ruby #{mkprims}"
end
