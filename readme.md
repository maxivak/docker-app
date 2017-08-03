# Docker app

Docker app is a tool to install and setup Docker containers.
It uses Dockerfile, Chef and other tools for provisioning.

Features:
* Config files are in Ruby.
* Manage complexity of running Docker containers for your environment in one place.
* Manage multiple containers


Other tools:
* docker-composer - with configs in yml


Docker-app is similar to docker-compose but has some more functionality to customize installation of servers on the host.


# Overview

Process of installing server in Docker container has the following stages:

Process of building and running container on the host machine:
* Build Docker image
    * it will create a Docker image on the host machine
    * build using Dockerfile or Chef provisioning
    
* Run Docker container
    * provision host machine - run scripts locally on the host machine. It can be shell script of Chef recipe
    * run container - `docker run`
    * provision container - run script inside the container. It can be shell script of Chef recipe

* Install systemd service on the host machine to run Docker container automatically (optional)

* Start/Stop container

* Destroy container

* Destroy image


Concepts of running Docker containers:
* you can rerun containers without losing data. Data is stored on the host machine and shared with container.




Build Docker image:
* from Dockerfile
* Chef provisioning (machine_image) 

Provision during installation container on the host machine by:
* running shell script inside container
* running Chef script inside container with Chef provisioning



# Installation

* Install gem:
```
gem install docker-app
```



# Quickstart

We will build and run a simple Docker container with Nginx server.

* install gem

```
gem install docker-app
```


* generate directory structure using generator

```
docker-app generate --name=nginx --type=chef
``` 

it will create a folder `nginx` with necessary directory structure inside.


* in the folder edit config file `config.rb` with common settings

```
common({
    'prefix' => "example-",
    'image_prefix' => 'example-',
    'dir_data' => '/disk3/data/my-examples/',

})

servers({
    'nginx'=>{
        # some server options here
    },


})


base({

})


```

* edit custom settings for the server in file `servers/nginx/config.rb`
 
```

add 'build', {
    "image_name" => "nginx",
    'build_type' => 'chef',
    "base_image" => {        "name" => "nginx",        "repository" => "nginx",        "tag" => "1.10"    },

}

add 'install', {
    "host" => {      'script_type' => 'chef_recipe',       'script' => 'install_host',    },
    "node" => {       'script_type' => 'chef_recipe',       'script' => 'install',    }
}

add 'docker', {
    "command"=> "nginx -g 'daemon off;'",
    'ports' => [
        [8080,80],
    ],
    'volumes' => [
        ['html', '/usr/share/nginx/html'],
        ['log/nginx', '/var/log/nginx/'],
    ],
    'links' => [    ]
}

add 'attributes', {
  'nginx' =>{
      "sitename" =>"mysite.local"
  },


}


```

* build Docker image

```
# from the folder with project

docker-app build
```

* run container

```
docker-app up
```

* check container is running
```
docker ps

# see container named example-nginx
```

* access container 

```
docker exec -ti example-nginx /bin/bash
```

* access container from browser

```
http://localhost:8080
```




# Install Docker container. Overview

Process:
* Create container - docker create
* setup network and other settings for container

* run provision to setup host machine. Script is running on the host machine.
```
{   
'provision'=>{
    'setup' => [
        {type: 'shell', ..}, 
        ..
    ]
    ...
}
```

* run provision to setup created (not running) container. 
Run script to copy/update files in container.

```
{   
'provision'=>{
   'setup'=> [
        {type: 'ruby', <<script_options>>}, 
        ..
    ]
    ...
}
```

* run container with `docker run`. Specify env variables, hostname and other options

* first provision of container - bootstrap script. Run script from inside running container only once. 
Script should be located inside container.
```
{   
'provision'=>{
   'bootstrap'=> [
        {type: 'chef', ..},
        ..
    ]
}
```

* provision to initialize container. 
Run script every time after container starts. Script should be located inside container.
```
{   
'provision'=>{
    'init'=> [
        {type: 'chef'},
        ..
    ]
}
```

* Use lock file to make sure the container does not start until the provision is finished.





# Basic usage

# Provision with shell script

* put scripts in `/path/to/project/ <<server_name>> / scripts / install.sh`


# Provisioning with Chef

Process of building and running container on the host machine:
* Build Docker image
    * it will create a Docker image on the host machine
    
* Run Docker container
    * provision host machine - run scripts locally on the host machine
    (recipe install_host.rb)
    * run container (docker run)
    * provision container - run script in the container
    (recipe install.rb)

* Install systemd service to run Docker container (optional)

* Start/Stop container

* Destroy container

* Destroy image


## Install server with Chef provisioning
 
* generate directory structure using generator
```
docker-app generate --name=nginx --type=chef
``` 

it will create a folder `nginx`

* in the folder edit config file `config.rb` with common settings

```

```

* edit custom settings for the server in file `servers/nginx/config.rb`
 
```
```

* build Docker image

```
# from the folder with project

docker-app build
```

* run container

```
docker-app up
```

* check container is running
```
docker ps
```

* access container from browser

```
http://localhost:8080
```





# Usage


* Build docker image

```
cd /path/to/servers

docker-app build -s server_name
```

* run docker container

```
cd /path/to/servers

docker-app run -s server_name
```

it will run container.

access container:

```
docker exec -ti container_name /bin/bash
```




# Provision



## Run provision after start

### Run provision from host machine

Run from outside container

```
'provision' => {
    "bootstrap" => [
        {'type' => 'shell', 'run_from'=>'host', 'script'=>'name=myserver ruby myprovision1.rb'     }
    ]
}
    
```

it will run script `name=myserver ruby myprovision1.rb` from the host machine.


### Provision with Chef

* in config file
```
    'provision' => {
        "bootstrap" => [
            {'type' => 'chef', "script"=>"", "dir_base"=>"/opt/bootstrap", "recipe"=>"server::bootstrap" },
        ]
    },
```

it will run chef provisioning:
```
cd /opt/bootstrap/ && chef-client -z -j /opt/bootstrap/config.json --override-runlist "recipe[server::bootstrap]"

```

config file with attributes (`/opt/bootstrap/config.json`) for chef-client is generated automatically.



## Development

After checking out the repo, run `bin/setup` to install dependencies. 
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).




# Configuration

* edit config.rb in your root folder

You can put all settings in this config.rb file and/or use config.rb file in each server's folder.

Config files:
```
/path/to/project/config.rb
/path/to/project/servers/server1/config.rb
/path/to/project/servers/server2/config.rb
```


## config.rb


* CHEF_COOKBOOKS - list of paths to chef cookbooks


# Build Docker image

Build types:
* 'none' - no build required
* 'Dockerfile' - using Dockerfile and docker build command
* 'chef' - using Chef provisioning (gem chef-provisioning-docker)
* 'packer' - using Packer tool


# Chef provisioning

* add additional paths for cookbooks

in folder with servers:

```
# /path/to/my/servers/.chef/knife.rb

cookbook_path cookbook_path+[
    '/path/to/my/cookbooks',
    '/path/to/my/other/cookbooks',
]

```


# Build Docker container with Chef

Example of building Docker container with Chef.

Assume that our server name is 'nginx'.


* edit config file 'myserver/config.rb'

```
####
```

* Chef recipes
* cookbooks/nginx/recipes/build.rb 
place chef resources to be included in the Docker image

* cookbooks/nginx/recipes/install.rb

* cookbooks/nginx/recipes/install_host.rb

* build

```
# run from the folder

docker-app build['nginx']
```

* shared data:
/disk3/data/server-api/nginx-front

data for nginx server:
* /etc/nginx/conf.d
* /var/www/html
* /var/log/nginx


* Main site - /var/www/html ==> /disk3/data/server-api/nginx-front/var/www/html

 

* Config


## Run container



## Manage multiple servers






# Build container

## Build from Dockerfile

* config for server
```
'build' => {
      'build_type' => 'Dockerfile',
      "image_name" => "myname",

      "base_image" => {} # not used
  },
```


## Build with Packer

* config for server
```
'build' => {
      'build_type' => 'packer',
      "image_name" => "myname",

      "base_image" => {
        "name" => "nginx",        
        "repository" => "nginx",        
        "tag" => "1.10"
      },
      
      "packer" => { options for packer }
  },
```

* options for packer

* cookbook_paths - list of paths
* recipe_name


* examples:
```
```


# Run container


## Run from existing image

* config for server
```
'build' => {
      'build_type' => 'none',
      "image_name" => "myname",

      "base_image" => {
          "name" => "mysql", 
          "repository" => "mysql", 
          "tag" => "3.4.9"
      },
  },
      
```

it will NOT build a new Docker image.



## Run Docker container with Chef

* run recipe install_host which runs on the host machine (not in container)
* run recipe install which runs from within the running container 



# Start Docker container

docker-app start -s server_name

it starts docker container which was previously created.

Process:
* Start docker container container with `docker start ..`
* Provision container



# Other tools

* packer - https://github.com/mitchellh/packer

Packer is a tool for creating machine images for multiple platforms from a single source configuration.



# Docker options for running container

* `run_extra_options` - additional options for docker run command
 
* hostname

```
{
..
servers({
    'zookeeper'=>{
    ...
        'docker'=> {
            ...
            'run_extra_options'=>'--hostname zookeeper'
        }
}
```



# Clear cache

Sometimes you need to clear cache with server info in chef-zero server

```
docker-app clear_cache
```


# Run in swarm mode

* commands

docker-app :up_swarm

docker-app :destroy_swarm


* config

```
docker: {
    # options here...
}
```

* swarm_network - network name
* swarm_options - options to pass to docker service create command



# Options

## prefix

prefix for image names, container names, and service names (for swarm mode)

* prefix - common prefix. Added to all names
* container_prefix - prefix for containers
* image_prefix - prefix for images
* service_prefix  - prefix for services
    
    
Example:
* container name = $prefix$container_prefix$name

```
prefix='my-'
container_prefix='test-'

container name will be like 
my-test-redis

```

    

# Provision

## Setup container

### Setup container with shell script

* run script from the host

```
'provision' => {
    "setup" => [
        {  'type' => 'shell',     'script' => 'scripts/mysetup.sh',  },
     ]
},
```

* it will run the script
```
scripts/mysetup.sh
```

## Bootstrap container

* first provision of container
* provision scripts run only once



### Bootstrap with shell script

* Dockerfile

* include script /opt/bootstrap/bootstrap.sh in container
```
ADD scripts/bootstrap.sh /opt/bootstrap/

RUN chmod +x /opt/bootstrap/bootstrap.sh

```

* config

```
'provision' => {
    "bootstrap" => [
        {  'type' => 'shell',     'script' => '/opt/bootstrap/bootstrap.sh',  },
     ]
},


```

## Provision with chef

docker-app up -s server_name

Process:
* docker create with docker options
    * entrypoint: /etc/bootstrap
* generate config with node attributes for chef and save it to temp/boostrap-__server__.json
* copy config file to container to /opt/bootstrap/config.json
* docker start 
* when container starts it runs /etc/bootstrap which
    * runs chef-client to provision server first time






# Network

* Docker container can be connected to multiple networks. 
Container has an IP in each network. 

Docker networks can be created using docker command `docker network create`


Docker-app allows you to manage networks for your container.






## multiple networks


* connect to multiple networks and specify default gateway

define IP in each network.

it assumes that networks 'my_bridge1' and 'my_overlay1' exist.


```
'docker'=> {
..
'network': {
   default_gateway: '192.168.1.1',
   networks: {
      {net: 'bridge'}, # default docker bridge
      {net: 'my_bridge1', ip: '10.1.0.12'},
      {net: 'my_overlay1', ip: '51.1.0.15'},
   }
   
}

}
```

in this example container will be connected to three networks:
     * docker default bridge named 'bridge'
     * custom docker network named 'my_bridge1' with ip='10.1.0.12'
     * custom docker network named 'my_overlay1'
     
     

create networks:
```
docker network create --driver bridge --subnet=51.1.0.0/16 --gateway=51.1.0.1  my_bridge1
docker network create -d macvlan --subnet=10.1.0.0/16  --gateway=10.1.0.1 --ip-range=10.1.12.0/24 -o parent=eth0 my_overlay1
```

see docker networks:
```
docker network ls
```


* check
```
docker exec -ti mycontainer bash

ip route

# sample output
...

```


## remove default Docker bridge network 


* Container will be connected to two networks and NOT connected to default Docker network 'bridge'

```
'docker'=> {
..
'network': {
   networks: {
      {net: 'bridge', action: 'remove'}, # remove default docker bridge
      {net: 'mybridge1', ip: '10.1.0.12'},
      {net: 'my_overlay1', ip: '51.1.0.15'},
   }
}

}
```


# Examples

* [Nginx with Mysql](https://github.com/maxivak/docker-nginx-mysql-example)


## Examples. Bootstrap scripts

### basic

* change root password

```
'provision' => {

    "bootstrap" => [
    
        {
            'type' => 'shell',
            'script'=>%Q(bash -c "echo 'root:newpass' | chpasswd")
        },
    ]
},
        
```

it will run command:
```
docker exec container_name  bash -c "sh /tmp/bootstrap.sh"
```


### run script on the host machine

* use option `run_from'=>'host'` for bootstrap script
```
'provision' => {
    "bootstrap" => [
        {
            'type' => 'shell',
            'script'=>'do smth...',
            'run_from'=>'host'
        },
    ]
},
     
```


### additional options for docker exec

* run script under another non-root user

```
'provision' => {
    "bootstrap" => [
        {
            'type' => 'shell',
            'script'=>%Q(bash -c "sh /tmp/bootstrap.sh"),
            'exec_options'=>'--user app'
        },
    ]
},

```

it will run command:
```
docker exec --user app container_name  bash -c "sh /tmp/bootstrap.sh"
```