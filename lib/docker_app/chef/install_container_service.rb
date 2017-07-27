base_dir = File.dirname(__FILE__)

#
require_relative 'lib/settings'

#
server_name = ENV['SERVER_NAME']
settings = Settings.load_settings_for_server(server_name)
#puts "ss = #{settings.attributes}"
#puts "container name = #{settings.container_name}"


# create systemd service
include_recipe 'server-name::install_container_service'
