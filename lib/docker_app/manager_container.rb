module DockerApp
class ManagerContainer

  def self.save_chef_config(settings)
    require 'json'
    filename = settings.filename_chef_config
    FileUtils.mkdir_p(File.dirname(filename))
    File.open(filename,"w+") do |f|
      f.write(settings.all_attributes.to_json)
    end

    true
  end


  def self.save_config_json(settings)
    require 'json'
    filename = settings.filename_config_json
    FileUtils.mkdir_p(File.dirname(filename))
    File.open(filename,"w+") do |f|
      f.write(settings.all_attributes.to_json)
    end

    true
  end




  ### run

  def self.run_container(server_name, settings={})
    puts "creating and running container.."
    #settings = load_settings(server_name)

    # generate config
    save_config_json(settings)


    # destroy
    destroy_container(server_name, settings)

    # create
    create_container(settings)


    # START && run provision after start
    start_container(name, settings)


    # TODO: systemd service
    #res_service = _install_service_container(settings)


    true
  end

  def self.create_container(settings)
    # create
    net_options = ""
    networks = settings['docker'].fetch('network', {}).fetch('networks', [])
    if networks && networks[0]
      network = networks[0]
      #puts "network=#{network}"
      net_options << "--net #{network['net']} "
      net_options << "--ip #{network['ip']} "  if network['ip']
      net_options << "--mac-address #{network['mac_address']} "  if network['mac_address']
    end


    cmd %Q(docker create --name #{settings.container_name} #{net_options} #{settings.docker_ports_string} #{settings.docker_volumes_string} #{settings.docker_volumes_from_string} #{settings.docker_links_string}  #{settings.run_extra_options_string} #{settings.run_env_variables_string} #{settings.image_name} #{settings['docker']['command']} #{settings['docker']['run_options']})

    # network
    setup_network(settings)
  end


  def self.setup_network(settings)
    container_name = settings.container_name

    # networks
    networks = settings['docker'].fetch('network', {}).fetch('networks', [])
    if networks
      ind = 0
      networks.each do |net|
        ind = ind + 1

        #
        next if net['action']=='remove'

        # skip first network
        next if ind==1

        # connect
        ip = net['ip']
        s_ip = "--ip #{ip}" if ip
        #puts %Q(docker network connect #{s_ip}  #{net['net']} #{settings.container_name})
        cmd %Q(docker network connect #{s_ip}  #{net['net']} #{settings.container_name})
      end

      # remove
      networks.each do |net|
        next unless net['action']=='remove'
        cmd %Q(docker network disconnect #{net['net']} #{settings.container_name})
      end
    end
  end




  def self.start_container(name, settings)
    ### BEFORE START
    # run setup provision scripts
    DockerApp::Provisioner::Base.run_provision_scripts_setup(settings)


    ### start
    cmd %Q(docker start #{settings.container_name})

    # wait
    wait_until_running(settings.container_name)

    ### AFTER START

    # setup
    setup_container_after_start(settings)

    # provision after start
    # run bootstrap provision scripts
    DockerApp::Provisioner::Base.run_provision_scripts_bootstrap(settings)

  end


  def self.wait_until_running(container_name)
    retries = 10
    until system("docker exec #{container_name} true") || retries < 0
      sleep 1
      retries = retries - 1
    end

    assert_container_running(container_name)
  end

  def self.assert_container_running(container_name)
    res = system("docker exec #{container_name} true")
    assert res, "Container #{container_name} is not running"
  end


=begin
  def self._prepare_provision_before_start_chef(settings, script)
    puts "_prepare_provision_before_start_chef"

    require_relative '../../lib/docker_app/provisioner/provisioner_chef'

    provisioner = DockerApp::Provisioner::Chef.new(settings)
    provisioner.copy_config_file

  end
=end

  def self.setup_container_after_start(settings)

    # default gateway
    network = settings['docker']['network']
    if network
      gateway = network['default_gateway']

      if gateway
        # fix default gateway
        #cmd %Q(docker exec #{settings.container_name} ip route change default via #{gateway} dev eth1)
        cmd %Q(docker exec #{settings.container_name} ip route change default via #{gateway})
      end
    end



    # fix hosts
    container_hosts = settings['docker']['hosts'] || []
    container_hosts.each do |r|
      #cmd %Q(docker exec #{settings.container_name} bash -c 'echo "#{r[0]} #{r[1]}" >>  /etc/hosts')
      cmd %Q(docker exec #{settings.container_name} sh -c 'echo "#{r[0]} #{r[1]}" >>  /etc/hosts')
    end
  end






  ### systemd service

  def self._install_service_container(settings)
    # not work
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} install_container_service.rb )

    # work
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} -j config_run_install_container_service.json )

    # work
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} --override-runlist 'recipe[server-api::install_container_service]' )

    #
    cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} -j config/config-#{settings.name}.json --override-runlist 'recipe[server-api::install_container_service]' )
  end


  def self._remove_service_container(settings)
    cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} -j config/config-#{settings.name}.json --override-runlist 'recipe[server-api::remove_container_service]' )
  end



=begin
  def self._run_container_chef(settings)
    # generate json config for chef
    save_chef_config(settings)

    # run chef
    #s_run = %Q(cd #{settings.name} && chef-client -z -j config.json -c ../.chef/knife.rb -N #{settings.name} ../lib/chef_container_run.rb)

    # good - 2016-nov-19
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} chef_run_container.rb)

    #
    res_chef = run_chef_recipe(settings, 'chef_run_container.rb')

    res_chef
  end

=end




  ###

  def self.destroy_container(server_name, settings)
   puts "destroying container #{server_name}..."

   # TODO: stop, remove systemd service
   #res_service = _remove_service_container(settings)

   #
   cmd %Q(docker rm -f #{settings.container_name} )



   # if chef
   if settings['build']['build_type']=='chef'
     return destroy_container_chef(settings)
   end

   #
   return true
 end


  def self.destroy_container_chef(settings)
    # destroy temp container
    cmd %Q(docker rm -f chef-converge.#{settings.image_name} )

    #
    res_chef = run_chef_recipe(settings, 'chef_destroy_container.rb')
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} chef_destroy_container.rb)

    #
    chef_remove_data(settings)

  end




  ### stop container

  def self.stop_container(server_name, settings)
    puts "stopping container #{server_name}..."

    #
    cmd %Q(docker stop #{settings.container_name} )

    #
    return true
  end


  ### run task on running container
  def self.exec_task(server_name, recipe_name)
    #raise 'not implemented'

    settings = load_settings(server_name)

    # check script exists
    script_path = "#{settings.name}/cookbooks/#{settings.name}/recipes/#{recipe_name}.rb"
    f = File.expand_path('.', script_path)

    if !File.exists?(f)
      puts "script not found: #{f}. Skipping"
      return false
    end

    #
    cmd %Q(SERVER_NAME=#{settings.name} chef-client -z --override-runlist 'recipe[server-api::exec_container]' )
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} --override-runlist 'recipe[#{settings.name}::#{recipe_name}]' )
    #cmd %Q(SERVER_NAME=#{settings.name} chef-client -z -N #{settings.name} chef_exec_container.rb )

    return true
  end


  ###
  def self.clear_cache(name, settings)
    # common cache
    cmd("rm -rf ~/.chef/cache")
    cmd("rm -rf ~/.chef/local-mode-cache")

    # cache for server
    cmd("rm -rf #{settings.dir_server_root}/.chef/local-mode-cache")
    #cmd("rm -rf ~/.chef/package-cache")

    # cache in gem
    cmd("rm -rf #{Config.dir_gem_root}/lib/docker_app/.chef/local-mode-cache")


  end

  ###

  def self.cmd(s)
    Command.cmd(s)
  end



  ### helpers - chef

  def self.run_chef_recipe(settings, recipe_rb)
    cmd %Q(cd #{Config.root_path} && SERVER_NAME=#{settings.name} SERVER_PATH=#{settings.dir_server_root} chef exec chef-client -z -N #{settings.container_name} -j #{settings.filename_config_json} -c #{chef_config_knife_path} #{chef_recipe_path(recipe_rb)} )
  end

  def self.run_chef_recipe_server_recipe(settings, server_recipe)
    cmd %Q(cd #{Config.root_path} && SERVER_NAME=#{settings.name} SERVER_PATH=#{settings.dir_server_root} chef exec chef-client -z -N #{settings.container_name} -c #{chef_config_knife_path} --override-runlist 'recipe[#{settings.name}::#{server_recipe}]' )
  end


  def self.chef_config_knife_path
    "#{Config.dir_gem_root}/lib/docker_app/chef/.chef/knife.rb"
  end

  def self.chef_recipe_path(p)
    "#{Config.dir_gem_root}/lib/docker_app/chef/#{p}"
  end


  def self.chef_remove_data(settings)
    #
    cmd %Q(cd #{Config.root_path} && chef exec knife node delete #{settings.chef_node_name}  -y -c #{chef_config_knife_path})

    # clean chef client, node
    cmd %Q(cd #{Config.root_path} && rm -f #{settings.filename_chef_node_json} )
    cmd %Q(cd #{Config.root_path} && rm -f #{settings.filename_chef_client_json} )
  end


  ### common helpers
  def self.assert(expression, string = "Assert failed")
    unless expression
      throw Exception.new string
    end
  end

end
end
