# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gcode/version'

Gem::Specification.new do |gem|
  gem.name          = 'gcode'
  gem.version       = Gcode::VERSION
  gem.authors       = ['Kaz Walker']
  gem.email         = ['kaz@printtopeer.com']
  gem.description   = %q{A basic Gcode parser and modifier.}
  gem.summary       = %q{This gem includes classes to evaluate, analyze and do simple modifications to RepRap flavoured Gcode and some MakerBot flavoured Gcode.}
  gem.homepage      = 'https://github.com/PrintToPeer/gcode'
  gem.license       = 'GPLv3'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.3'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'
end
