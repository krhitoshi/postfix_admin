# -*- encoding: utf-8 -*-
require File.expand_path('../lib/postfix_admin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_development_dependency 'thor'
  gem.add_development_dependency 'data_mapper'
  gem.add_development_dependency 'dm-mysql-adapter'

  gem.authors       = ["Hitoshi Kurokawa"]
  gem.email         = ["hitoshi@nextseed.jp"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "postfix_admin"
  gem.require_paths = ["lib"]
  gem.version       = PostfixAdmin::VERSION
end
