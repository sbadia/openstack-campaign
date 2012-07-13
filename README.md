OpenStack-campaign
==================

Deploy openstack on Grid'5000

Grid'5000
---------
[Grid'5000](https://www.grid5000.fr/) a scientific instrument designed to support experiment-driven research in all areas of computer science related to parallel, large-scale or
distributed computing and networking.

# Launch tests
    gem install g5k-campaign --source http://g5k-campaign.gforge.inria.fr/pkg --user-install --no-ri --no-rdoc -p http://proxy:3128
    https_proxy='http://proxy:3128' git clone https://github.com/sbadia/openstack-campaign.git
    ruby bin/openstackg5k.rb -h
    ruby bin/openstackg5k.rb --nodes 2 --walltime 5 --no-clean

    sshing on the cloud controller (first node).
    bash nova_test.sh cirros

## Dashboard
    ssh -L 8888:cloud-controller:80 nancy.user
    http://localhost:8888 (login: admin, passwd: keystone_admin)

* Note: gems libxml-ruby, rake, mixlib-cli, json and net-ssh-multi already installed on g5k frontends.

# For developpers
## Submodules
1. `git submodule init`
2. `git submodule update`
3. `git submodule foreach git pull origin master`
