OpenStack-campaign
==================

Deploy openstack on Grid'5000

Grid'5000
---------
[Grid'5000](https://www.grid5000.fr/) a scientific instrument designed to support experiment-driven research in all areas of computer science related to parallel, large-scale or
distributed computing and networking.

Launch tests
------------
1. `gem install g5k-campaign --source http://g5k-campaign.gforge.inria.fr/pkg --user-install --no-ri --no-rdoc`
2. `git clone git://github.com/sbadia/openstack-campaign.git`
3. `ruby bin/openstackg5k.rb -h`
4. `ruby bin/openstackg5k.rb --nodes 2 --env ubuntu-x64-br --walltime 5 --no-clean`

* Note: gems libxml-ruby, rake, mixlib-cli, json and net-ssh-multi already installed on g5k frontends.

Submodules
-----------------
1. `git submodule init`
2. `git submodule update`
3. `git submodule foreach git pull origin master`
