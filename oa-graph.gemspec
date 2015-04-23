lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oa/graph/version'

Gem::Specification.new do |spec|
  spec.name          = 'oa-graph'
  spec.version       = OA::Graph::VERSION
  spec.authors       = ['Naomi Dushay']
  spec.email         = ['ndushay@stanford.edu', 'darren.weber@stanford.edu']
  spec.homepage      = 'https://github.com/sul-dlss/oa-graph'
  spec.summary       = %(Wrapper class for RDF::Graph that adds methods
 specific to OpenAnnotation graphs. http://www.openannotation.org/spec/core/)

  spec.license       = 'Apache-2.0'

  spec.files         = Dir['lib/**/*', 'Rakefile', 'README.md']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'linkeddata'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'pry-byebug'
end
