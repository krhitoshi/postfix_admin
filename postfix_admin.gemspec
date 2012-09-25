# -*- encoding: utf-8 -*-
require File.expand_path('../lib/postfix_admin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'thor'
  gem.add_dependency 'data_mapper'
  gem.add_dependency 'dm-mysql-adapter'

  gem.authors       = ["Hitoshi Kurokawa"]
  gem.email         = ["hitoshi@nextseed.jp"]
  gem.description   = %q{Command Line Tools of PostfixAdmin}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/krhitoshi/postfix_admin"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "postfix_admin"
  gem.require_paths = ["lib"]
  gem.version       = PostfixAdmin::VERSION
end
