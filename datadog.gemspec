# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'datadog/version'

Gem::Specification.new do |spec|
  spec.name          = 'datadog'
  spec.version       = Datadog::VERSION
  spec.authors       = ['Mike Fiedler']
  spec.email         = ['miketheman@gmail.com']
  spec.description   = 'A client library for Datadog API interaction'
  spec.summary       = 'A full-featured client library for Datadog'
  spec.homepage      = 'http://www.datadog.com'
  spec.licenses      = ['MIT']

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '~> 2.0'

  spec.add_dependency 'sawyer', '~> 0.6.0'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop', '~> 0.29.0'
end
