# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "btjunkie/version"

Gem::Specification.new do |s|
  s.name        = "btjunkie"
  s.version     = Btjunkie::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Linus Oleander"]
  s.email       = ["linus@oleander.nu"]
  s.homepage    = ""
  s.summary     = %q{The Unofficial API for btjunkie.org}
  s.description = %q{The Unofficial API for btjunkie.org.}

  s.rubyforge_project = "btjunkie"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency("rest-client")
  s.add_dependency("abstract")
  
  s.add_development_dependency("rspec")
  s.add_development_dependency("webmock")
end