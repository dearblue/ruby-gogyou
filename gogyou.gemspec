
Gem::Specification.new do |spec|
  spec.name = "gogyou"
  spec.version = "0.2"
  spec.summary = "define the data struct for packing and unpacking to binary strings"
  spec.license = "2-clause BSD License"
  spec.author = "dearblue"
  spec.email = "dearblue@users.sourceforge.jp"
  spec.homepage = "http://sourceforge.jp/projects/rutsubo/"
  spec.description = <<EOS
gogyou is a library for define the data struct for packing and unpacking to binary strings.

The C style types are usable.

Also:
- Define nested struct is possible.
- By using the typedef, you can define any class.
- Definition of a one-dimensional array is possible.
EOS
  spec.files = %w(
    README.txt
    LICENSE.txt
    lib/gogyou.rb
  )

  spec.rdoc_options = %w(-e UTF-8 -m README.txt)
  spec.extra_rdoc_files = %w(README.txt LICENSE.txt lib/gogyou.rb)
  spec.has_rdoc = false
  spec.required_ruby_version = ">= 1.9.3"
end
