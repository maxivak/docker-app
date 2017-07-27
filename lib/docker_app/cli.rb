module DockerApp
class CLI < Thor
  include Thor::Actions

  def self.source_root
    #File.dirname(__FILE__)
    File.expand_path('../../templates', __FILE__)
  end


  ##
  # [build]
  #
  #
  desc 'build', 'Build Docker image'

  long_desc <<-EOS.gsub(/^ +/, '')
  Build Docker image.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def build
    puts "building images..."

    opts = options
    #puts "opt from command line: #{options.inspect}"


    warnings = false
    errors = false

    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        #puts "s: #{server_settings.inspect}"

        ManagerImage.destroy_image(name, server_settings)
        ManagerImage.build_image(name, server_settings)
      end


    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end


  ##
  # [destroy_image]
  #
  #
  desc 'destroy_image', 'Destroy Docker image'

  long_desc <<-EOS.gsub(/^ +/, '')
  Destroy Docker image.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def destroy_image
    puts "destroying image..."

    warnings = false
    errors = false

    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        ManagerImage.destroy_image(name, server_settings)
      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end


  ##
  # [up]
  #
  #
  desc 'up', 'Run Docker container'

  long_desc <<-EOS.gsub(/^ +/, '')
  Run Docker container.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def up
    puts "running..."

    opts = options

    warnings = false
    errors = false


    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        if server_settings.is_swarm_mode?
          ManagerSwarm.destroy_service(name, server_settings)
          ManagerSwarm.create_service(name, server_settings)
        else
          ManagerContainer.destroy_container(name, server_settings)
          ManagerContainer.run_container(name, server_settings)
        end

      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end


  ##
  # [start]
  #
  #
  desc 'start', 'Start Docker container'

  long_desc <<-EOS.gsub(/^ +/, '')
  Start Docker container.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def start
    puts "starting..."

    opts = options

    warnings = false
    errors = false
    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        ManagerContainer.start_container(name, server_settings)
      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end



  ##
  # [destroy]
  #
  #
  desc 'destroy', 'Destroy Docker container'

  long_desc <<-EOS.gsub(/^ +/, '')
  Destroy Docker container.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def destroy
    puts "destroying..."

    opts = options

    warnings = false
    errors = false

    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        if server_settings.is_swarm_mode?
          ManagerSwarm.destroy_service(name, server_settings)
        else
          ManagerContainer.destroy_container(name, server_settings)
        end

      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end




  ##
  # [stop]
  #
  #
  desc 'stop', 'Stop Docker container(s)'

  long_desc <<-EOS.gsub(/^ +/, '')
  Stop containers.
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def stop
    puts "stopping..."

    opts = options

    warnings = false
    errors = false


    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        ManagerContainer.stop_container(name, server_settings)
      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end





  ##
  # [clear_cache]
  #
  #
  desc 'clear_cache', 'clear cache'

  long_desc <<-EOS.gsub(/^ +/, '')
  clear_cache
  EOS

  method_option :server,
                :aliases  => ['-s', '--server'],
                :required => false,
                :type     => :string,
                :desc     => "Server name"

  method_option :root_path,
                :aliases  => '-r',
                :type     => :string,
                :default  => '',
                :desc     => 'Root path to base all relative path on.'

  method_option :config_file,
                :aliases  => '-c',
                :type     => :string,
                :default  => 'config.rb',
                :desc     => 'Path to your config.rb file.'

  def clear_cache
    puts "clear_cache..."

    opts = options

    warnings = false
    errors = false

    begin
      Config.load(options)

      Config.servers.each do |name, server_settings|
        #server_settings = Settings.load_settings_for_server(name)

        ManagerContainer.clear_cache(name, server_settings)
      end

    rescue Exception => err
      puts "exception: #{err.inspect}"
      raise err
      exit(3)
    end

    exit(errors ? 2 : 1) if errors || warnings

  end


  ### generators

  ##
  # [generate new project]
  #
  #
  desc 'generate', 'Generate new project'

  long_desc <<-EOS.gsub(/^ +/, '')
  Generate new project
  EOS

  method_option :name,
                :aliases  => ['-n', '--name'],
                :required => false,
                :type     => :string,
                :desc     => "Project name"


  method_option :type,
                :aliases  => ['-t', '--type'],
                :required => false,
                :type     => :string,
                :default => 'chef',
                :desc     => "Provision type"

  def generate
    puts "creating project..."

    puts "opts: #{options}"
    name = options[:name]
    @name = name

    empty_directory(name)

    if options[:type] == 'chef'
      source_base_dir = "example-chef"

      empty_directory("#{name}/servers")
      template "#{source_base_dir}/config.rb.erb", "#{name}/config.rb"


      # server
      source_server_dir = "#{source_base_dir}/servers/server1"
      server_dir = "#{name}/servers/#{name}"

      directory("#{source_base_dir}/servers/server1/.chef", "#{server_dir}/.chef")


      # cookbooks
      empty_directory("#{server_dir}/cookbooks")
      empty_directory("#{server_dir}/cookbooks/#{name}")
      empty_directory("#{server_dir}/cookbooks/#{name}/recipes")
      empty_directory("#{server_dir}/cookbooks/#{name}/templates")

      template "#{source_server_dir}/config.rb.erb", "#{server_dir}/config.rb"
      template "#{source_server_dir}/cookbooks/server1/metadata.rb.erb", "#{server_dir}/cookbooks/#{name}/metadata.rb"

      directory("#{source_base_dir}/servers/server1/cookbooks/server1/recipes", "#{server_dir}/cookbooks/#{name}/recipes")
      directory("#{source_base_dir}/servers/server1/cookbooks/server1/templates", "#{server_dir}/cookbooks/#{name}/templates")
      copy_file("#{source_base_dir}/servers/server1/cookbooks/server1/README.md", "#{server_dir}/cookbooks/#{name}/README.md")


    end



  end


  ### helpers




end
end
