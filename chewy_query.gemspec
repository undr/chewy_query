# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chewy_query/version'

Gem::Specification.new do |spec|
  spec.name          = 'chewy_query'
  spec.version       = ChewyQuery::VERSION
  spec.authors       = ['pyromaniac', 'undr']
  spec.email         = ['kinwizard@gmail.com', 'undr@yandex.ru']
  spec.summary       = %q{The query builder for ElasticSearch which was extracted from Chewy.}
  spec.description   = %q{The query builder for ElasticSearch which was extracted from Chewy.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 3.2'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'its'
end
