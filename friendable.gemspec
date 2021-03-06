# -*- encoding: utf-8 -*-
require File.expand_path('../lib/friendable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yuki Nishijima"]
  gem.email         = ["mail@yukinishijima.net"]
  gem.description   = %q{Redis backed friendship engine for your Ruby models}
  gem.summary       = %q{Redis backed friendship engine for your Ruby models}
  gem.homepage      = "https://github.com/yuki24/friendable"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "friendable"
  gem.require_paths = ["lib"]
  gem.version       = Friendable::VERSION

  gem.add_dependency 'msgpack'
  gem.add_dependency 'activesupport', '>= 3.0.0'
  gem.add_dependency 'redis-namespace'
  gem.add_dependency 'keytar'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'activerecord'
  gem.add_development_dependency 'sqlite3'
end
