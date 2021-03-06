# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'd13n/version'

Gem::Specification.new do |spec|
  spec.name          = "d13n"
  spec.version       = D13n::VERSION::STRING
  spec.authors       = ["Ben Wu"]
  spec.email         = ["wucheokman@gamil.com"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{Write a longer description or delete this line.}
  spec.homepage      = "http://github.com/cheokman"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ['d13n']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "bundler", "2.1.4"
  spec.add_runtime_dependency 'statsd-instrument', '~> 2.2', '>= 2.2.0'
  spec.add_runtime_dependency 'config_kit', '0.1.1'
end