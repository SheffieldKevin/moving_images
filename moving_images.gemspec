# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moving_images/version'

Gem::Specification.new do |spec|
  spec.name          = "moving_images"
  spec.version       = MovingImages::VERSION
  spec.authors       = ["Kevin Meaney"]
  spec.email         = ["ktam@yvs.eu.com"]
  spec.summary       = %q{Ruby interface for using MovingImages}
  spec.description   = %q{Currently not ready for general use}
  spec.homepage      = "http://blog.yvs.eu.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
