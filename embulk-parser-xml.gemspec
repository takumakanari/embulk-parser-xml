# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-xml"
  spec.version       = "0.0.6"
  spec.authors       = ["Takuma kanari"]
  spec.email         = ["chemtrails.t@gmail.com"]
  spec.summary       = %q{Embulk parser plugin for XML}
  spec.description   = %q{XML parser plugin is Embulk plugin to fetch entries in xml format.}
  spec.homepage      = "https://github.com/takumakanari/embulk-parser-xml"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6"
  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency 'embulk', ['>= 0.8.8']
  spec.add_development_dependency "rake", "~> 10.0"
end
