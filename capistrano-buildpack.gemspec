# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano-buildpack/version'

Gem::Specification.new do |gem|
  gem.name          = "capistrano-buildpack"
  gem.version       = Capistrano::Buildpack::VERSION
  gem.authors       = ["Pete Keen"]
  gem.email         = ["pete@bugsplat.info"]
  gem.description   = %q{Deploy 12-factor applications using Capistrano}
  gem.summary       = %q{Deploy 12-factor applications using Capistrano}
  gem.homepage      = "https://github.com/peterkeen/capistrano-buildpack"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
