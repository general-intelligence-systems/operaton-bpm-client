# frozen_string_literal: true

require_relative "lib/operaton/bpm/client/version"

Gem::Specification.new do |spec|
  spec.name = "operaton-bpm-client"
  spec.version = Operaton::Bpm::Client::VERSION
  spec.authors = ["Nathan K"]
  spec.email = ["nathankidd@hey.com"]

  spec.summary = "Operaton External Task Client for Ruby"
  spec.description = "A faithful Ruby recreation of the Operaton (org.operaton.bpm.client) " \
                     "Java external task client: subscribe to topics, fetch and lock external " \
                     "tasks, and complete them against the Operaton REST API."

  spec.homepage = "https://github.com/general-intelligence-systems/operaton-bpm-client"

  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "base64"
  spec.add_dependency "logger"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "scampi", "~> 1.0"
  spec.add_development_dependency "lefthook", "~> 2.1"
end
