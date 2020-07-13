require File.expand_path('../lib/postfix_admin/version', __FILE__)

Gem::Specification.new do |gem|
  gem.add_dependency 'thor', '~> 1.0.1'
  gem.add_dependency 'activerecord', '~> 6.0.3'
  gem.add_dependency 'mysql2', '>= 0.5.3'
  gem.add_development_dependency 'rake', '~> 13.0.1'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'rspec', '~> 3.9.0'

  gem.authors       = ["Hitoshi Kurokawa"]
  gem.email         = ["hitoshi@nextseed.jp"]
  gem.description   = %q{Command Line Tools of PostfixAdmin}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/krhitoshi/postfix_admin"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "postfix_admin"
  gem.require_paths = ["lib"]
  gem.version       = PostfixAdmin::VERSION
end
