$:.unshift File.expand_path("../lib", __FILE__)
require "turbot_runner/version"

Gem::Specification.new do |gem|
  gem.name    = "turbot-runner"
  gem.version = TurbotRunner::VERSION

  gem.author      = "OpenCorporates"
  gem.email       = "bots@opencorporates.com"
  gem.homepage    = "http://turbot.opencorporates.com/"
  gem.summary     = "Utilities for running bots with Turbot"
  gem.license     = "MIT"

  # use git to list files in main repo
  gem.files = %x{ git ls-files }.split("\n").select do |d|
    d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|schema/)}
  end

  submodule_files = %x{git submodule foreach --recursive git ls-files}.split("\n").select do |d|
    d =~ %r{^(schemas/)}
  end.map{|x| "schema/#{x}"}

  gem.files.concat(submodule_files)

  gem.required_ruby_version = '>=1.9.2'

#  gem.add_dependency "activesupport", '~>4.1.0'
  gem.add_dependency "json-schema", '2.5.0'
end
