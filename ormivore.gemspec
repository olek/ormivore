lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'ormivore/version'

Gem::Specification.new do |spec|
  spec.name = "ormivore"
  spec.version = ORMivore::VERSION

  spec.licenses = ["MIT"]
  spec.authors = ["Olek Poplavsky"]
  spec.email = "olek@woodenbits.com"
  spec.summary = "Simple ORM framework for **long lived** ruby projects with a twist."
  spec.description = "ORM framework that values simplity, immutablity, layering, and maintenability over short term velocity"
  spec.homepage = "http://github.com/olek/ormivore"

  spec.require_paths = ["lib"]

  require 'rake'
  spec.files = FileList['lib/**/*.rb', '[A-Z]*', 'spec/**/*', 'app/**/*.rb', 'db/*.yml'].to_a

  spec.test_files =
    spec.files.grep(%r{^spec/}) + 
    spec.files.grep(%r{^app/})

  spec.required_ruby_version = ">= 1.9.3"
  spec.required_rubygems_version = ">= 1.3.6"

  spec.add_development_dependency(%q<rspec>, ["~> 2.13"])
  spec.add_development_dependency(%q<bundler>, ["~> 1.1"])
end
