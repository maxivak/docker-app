# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_app/version'
#require File.expand_path('lib/docker_app/version')


Gem::Specification.new do |spec|
  spec.name          = "docker-app"
  spec.version       = DockerApp::VERSION
  spec.authors       = ["Max Ivak"]
  spec.email         = ["max.ivak@gmail.com"]

  spec.summary       = 'Docker application installer'
  spec.description   = "Run Docker containers and provision with Chef, shell and other tools"
  spec.homepage      = "https://github.com/maxivak/docker-app"
  spec.license       = "MIT"



  #spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"

  #s.add_dependency 'httparty'
  #s.add_dependency 'json'


  #spec.add_dependency 'ostruct'
  spec.add_dependency 'thor'
end
