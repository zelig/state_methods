# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'state_methods/version'
DESC = %q{declarative state aware method definitions}

Gem::Specification.new do |gem|
  gem.name          = "state_methods"
  gem.version       = StateMethods::VERSION
  gem.authors       = ["zelig"]
  gem.email         = ["viktor.tron@gmail.com"]
  gem.description   = DESC
  gem.summary       = DESC
  gem.homepage      = "https://github.com/zelig/state_methods.git"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'debugger'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'activemodel'
  gem.add_development_dependency 'state_machine'

end
