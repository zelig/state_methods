# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "state_methods/version"

Gem::Specification.new do |s|
  s.name        = "state_methods"
  s.version     = StateMethods::VERSION
  s.authors     = ["zelig"]
  s.email       = ["viktor.tron@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "state_methods"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
