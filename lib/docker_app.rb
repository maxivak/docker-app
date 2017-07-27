require "docker_app/version"

require 'thor'

LIBRARY_PATH = File.join(File.dirname(__FILE__), 'docker_app')

module DockerApp


  ##
  # Require base files
  %w{
    config
    command
    cli
    server_settings
    manager_image
    manager_container
    manager_swarm
    provisioner/base
    provisioner/chef
  }.each {|lib| require File.join(LIBRARY_PATH, lib) }
end
