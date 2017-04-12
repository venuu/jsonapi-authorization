# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi/authorization/version'

Gem::Specification.new do |spec|
  spec.name          = "jsonapi-authorization"
  spec.version       = JSONAPI::Authorization::VERSION
  spec.authors       = ["Vesa Laakso", "Emil Sågfors"]
  spec.email         = ["laakso.vesa@gmail.com", "emil.sagfors@iki.fi"]
  spec.license       = "MIT"

  spec.summary       = "Generic authorization for jsonapi-resources gem"
  spec.description   = "Adds generic authorization to the jsonapi-resources gem using Pundit."
  spec.homepage      = "https://github.com/venuu/jsonapi-authorization"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jsonapi-resources", "~> 0.9"
  spec.add_dependency "pundit", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 1.3"
  spec.add_development_dependency "pry-doc", "~> 0.6"
  spec.add_development_dependency "pry-rails", "~> 0.3.4"
  spec.add_development_dependency "rubocop", "~> 0.36.0"
  spec.add_development_dependency "phare", "~> 0.7.1"
end
