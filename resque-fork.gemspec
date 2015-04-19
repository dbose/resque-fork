# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'resque/fork/version'

Gem::Specification.new do |spec|
  spec.name          = "resque-fork"
  spec.version       = Resque::Fork::VERSION
  spec.authors       = ["dbose"]
  spec.email         = ["debasish.bose@fairfaxmedia.com.au"]

  spec.summary       = %q{Distributed orchestrator using resque}
  spec.description   = %q{Distributed orchestrator using resque}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir["README.md","Gemfile","Rakefile", "spec/*", "lib/**/*"]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency   "redis-namespace", "~> 1.3"
  spec.add_dependency   "resque", "1.25.2"
  spec.add_dependency   "resque-pause"
  spec.add_dependency   "pry"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
