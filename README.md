# OpenStack-campaign

A tool for deploy openstack on Grid'5000

## Grid'5000

[Grid'5000](https://www.grid5000.fr/) a scientific instrument designed to support experiment-driven research in all areas of computer science related to parallel, large-scale or
distributed computing and networking.

## OpenStack

[OpenStack](http://www.openstack.org) OpenStack is a cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter, all managed through a dashboard that gives administrators control while empowering their users to provision resources through a web interface.

# Installation

    $ ssh nancy.g5k
    $ gem install g5k-campaign --source http://g5k-campaign.gforge.inria.fr/pkg --user-install --no-ri --no-rdoc -p http://proxy:3128
    $ https_proxy='http://proxy:3128' git clone https://github.com/sbadia/openstack-campaign.git

## Prerequisites
### Restfully
This tool uses the `Restfully` <http://github.com/crohr/restfully> ruby gem to connect to the Grid'5000 API.
You MUST set up a specific configuration file on the machine from where you will run `openstackg5k` commands.
The recommended location for this file is in `~/.restfully/api.grid5000.fr.yml`. You can generate one using:

    $ mkdir ~/.restfully
    $ echo "
    base_uri: https://api.grid5000.fr/stable/grid5000
    cache: false
    " > ~/.restfully/api.grid5000.fr.yml
    $ chmod 0600 ~/.restfully/api.grid5000.fr.yml

### Puppetlabs openstack

    $ cd openstack-campaign;git submodule init
    $ https_proxy='http://proxy:3128' git submodule update

# Openstackg5k
## Usage
    $ ruby bin/openstackg5k -h
    * Usage: bin/openstackg5k.rb (options)
        -u, --uri URI                    API Base URI (default: stable API)
        -e, --env ENV_NAME               Name of then environment to deploy (default: ubuntu-x64-br@sbadia)
        -j, --name JOB_NAME              The name of the job (default: openstackg5k)
        -k, --key KEY                    Name of then SSH key for the deployment (default: /home/sbadia/.ssh/id_dsa.pub)
        -l, --log-level LEVEL            Set log level (debug, info, warn, error, fatal)
        -c, --no-clean                   Disable restfully clean (jobs/deploy)
        -n, --nodes Num Nodes            Number of nodes (default: 4)
        -s, --site SITE                  Site to launch job (default: nancy)
        -v, --version                    Show Openstackg5k version
        -w, --walltime WALLTIME          Walltime of the job (default: 2) hours
        -h, --help                       Show this message

## Launch an experiment
    $ ruby bin/openstackg5k --nodes 2 --walltime 5 --no-clean

sshing on the cloud controller (first node) and run.

    $ bash /tmp/nova_test.sh cirros

## Dashboard
    $ ssh -L 8888:<cloud-controller>:80 nancy.user
    $ http://localhost:8888 (login: admin, passwd: keystone_admin)

* Note: gems libxml-ruby, rake, mixlib-cli, json and net-ssh-multi already installed on g5k frontends.

# For developpers
## Submodules
    git submodule foreach git pull origin master
