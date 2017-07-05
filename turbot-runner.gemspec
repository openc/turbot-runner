require File.expand_path('../lib/turbot_runner/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name    = "turbot-runner"
  gem.version = TurbotRunner::VERSION

  gem.author      = "OpenCorporates"
  gem.email       = "bots@opencorporates.com"
  gem.homepage    = "http://turbot.opencorporates.com/"
  gem.summary     = "Utilities for running bots with Turbot"
  gem.license     = "MIT"

  gem.files         = `git ls-files`.split("\n") + %x{git submodule foreach --quiet --recursive git ls-files schemas}.split("\n").map{|filename| "schema/#{filename}"}
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>=1.9.2'

  gem.add_dependency "activesupport", "~> 4.1.4"
  gem.add_dependency "openc-json_schema"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", "~> 3.4.0"
end
