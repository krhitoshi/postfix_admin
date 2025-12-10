require File.expand_path("../lib/postfix_admin/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "postfix_admin"
  gem.version       = PostfixAdmin::VERSION
  gem.authors       = ["Hitoshi Kurokawa"]
  gem.email         = ["hitoshi@nextseed.jp"]

  gem.summary       = gem.description
  gem.description   = %q{Command Line Tool for PostfixAdmin}
  gem.homepage      = "https://github.com/krhitoshi/postfix_admin"

  gem.required_ruby_version = ">= 2.7.0", "< 3.5"

  gem.add_dependency "thor", "~> 1.3.1"
  gem.add_dependency "activerecord", "~> 7.1.0"
  gem.add_dependency "mysql2", "~> 0.5"
  gem.add_dependency "terminal-table", "~> 3.0.2"
  gem.add_development_dependency "pry"
  gem.add_development_dependency "factory_bot", "~> 6.3.0"
  gem.add_development_dependency "rake", "~> 13.2.1"
  gem.add_development_dependency "rubocop"
  gem.add_development_dependency "rspec", "~> 3.13.0"
  gem.add_development_dependency "observer" # Required for Ruby 3.4+

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gem.files         = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  gem.bindir        = "exe"
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})

  gem.require_paths = ["lib"]
end
