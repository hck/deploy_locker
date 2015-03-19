# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deploy_locker/version'

Gem::Specification.new do |spec|
  spec.name          = "deploy_locker"
  spec.version       = DeployLocker::VERSION
  spec.authors       = ["hck", "yanivpr"]
  spec.email         = []
  spec.summary       = %q{Deployment locker service}
  spec.description   = %q{Deployment locking service which persists locking state for each user/project and rejects deployments while locking for project is not released}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.2.0"
  spec.add_development_dependency "rack-test", "~> 0.6.3"
  spec.add_development_dependency "webmock", "~> 1.20.4"

  spec.add_runtime_dependency "sinatra", "~> 1.4"
  spec.add_runtime_dependency "redis", "~> 3.0"
  spec.add_runtime_dependency "unicorn", "~> 4.8"
  spec.add_runtime_dependency "slack-notify", ">= 0.4.1"
end
