# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'libcx320/version'

Gem::Specification.new do |spec|
  spec.name          = "libcx320"
  spec.version       = LibCX320::VERSION
  spec.authors       = ["Holger Arndt", "Lars Kanis"]
  spec.email         = ["arndt@comcard.de", "kanis@comcard.de"]
  spec.summary       = %q{Driver for Retransfer Printer CX-320}
  spec.description   = %q{Driver for Retransfer Printer CX-320. Usable per PCP05CT.DLL or LIBUSB.}
  spec.homepage      = ""
  spec.license       = "MIT"
  spec.metadata['allowed_push_host'] = "http://ccgems"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
