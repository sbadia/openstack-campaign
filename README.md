# Openstack-campaign

A tool for deploy openstack on Grid'5000 (Tutorial available [here](https://www.grid5000.fr/mediawiki/index.php/OpenStack) or [here](https://www.grid5000.fr/mediawiki/index.php/Deploying_OpenStack_using_KaVLAN))

## Infos

### Grid'5000

[Grid'5000](https://www.grid5000.fr/) a scientific instrument designed to support experiment-driven research in all areas of computer science related to parallel, large-scale or
distributed computing and networking.

### OpenStack

[OpenStack](http://www.openstack.org) OpenStack is a cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter, all managed through a dashboard that gives administrators control while empowering their users to provision resources through a web interface.

### Puppetlabs

[Puppetlabs](http://www.puppetlabs.org) Puppet Open Source is a flexible, customizable framework available under the Apache 2.0 license designed to help system administrators automate the many repetitive tasks they regularly perform. As a declarative, model-based approach to IT automation, it lets you define the desired state – or the “what” – of your infrastructure using the Puppet configuration language. Once these configurations are deployed, Puppet automatically installs the necessary packages and starts the related services, and then regularly enforces the desired state. In automating the mundane, Puppet frees you to work on more challenging projects with higher business impact.

## Usage

* Reserve nodes using OAR

    ```
    oarsub -t deploy -l {"type='kavlan'"}/vlan=1+/nodes=3,walltime=03:00:00 -r "2013-07-10 09:00:00" -n "openstack"
    ```

* When reservation is running, connect using your job id, and launch deployment

    ```
    oarsub -C <jobid>
    ```

1. If you want to use cinder volumes (like amazon EBS, block storage)

    ```
    wget http://apt.grid5000.fr/cloud/openstack-tuto-kadeploy-custom.tgz
    tar xvzf openstack-tuto-kadeploy-custom.tgz
    kadeploy3 -f $OAR_NODEFILE -e ubuntu-x64-1204-parted --vlan `kavlan -V` -k --set-custom-operations ./customparted.yml
    ```

2. Otherwise

    ```
    kadeploy3 -f $OAR_NODEFILE -e ubuntu-x64-1204 -k --vlan `kavlan -V`
    ```

* Generate kavlan nodes file

    ```
    kavlan -l > ~/kavlan_nodes
    ```

* Download lastest openstack-campaign from git and fetch puppet modules (from puppet forge)
    ```
    https_proxy=http://proxy:3128 git clone https://github.com/sbadia/openstack-campaign
    ```
    ```
    cd openstack-campaign
    ```
    ```
    gem install --no-ri --no-rdoc puppet -v 2.7.14 --user-install
    http_proxy=http://proxy:3128 $HOME/.gem/ruby/1.8/bin/puppet module install puppetlabs/openstack --version 2.0.0 --modulepath $(pwd)/modules
    ```

    ```
    [20:10] G5K ❯ ~ » http_proxy=http://proxy:3128 puppet module install puppetlabs/openstack --version 2.0.0 --modulepath $(pwd)/modules
    Preparing to install into /home/sbadia/openstack-campaign/modules ...
    Downloading from http://forge.puppetlabs.com ...
    Installing -- do not interrupt ...
    /home/sbadia/openstack-campaign/modules
    └─┬ puppetlabs-openstack (v2.0.0)
      ├─┬ puppetlabs-cinder (v2.0.0)
      │ ├── cprice404-inifile (v0.10.3)
      │ ├── dprince-qpid (v1.0.1)
      │ ├── puppetlabs-mysql (v0.8.1)
      │ ├─┬ puppetlabs-rabbitmq (v2.1.0)
      │ │ └── puppetlabs-apt (v1.2.0)
      │ └── puppetlabs-stdlib (v4.1.0)
      ├── puppetlabs-glance (v2.0.0)
      ├─┬ puppetlabs-horizon (v2.0.0)
      │ ├─┬ puppetlabs-apache (v0.6.0)
      │ │ └── puppetlabs-firewall (v0.3.1)
      │ └── saz-memcached (v2.1.0)
      ├── puppetlabs-keystone (v2.0.0)
      ├─┬ puppetlabs-nova (v2.0.0)
      │ └── duritong-sysctl (v0.0.1)
      └─┬ puppetlabs-swift (v2.0.0)
        ├── puppetlabs-rsync (v0.1.0)
        ├── puppetlabs-xinetd (v1.1.0)
        ├── ripienaar-concat (v0.2.0)
        └── saz-ssh (v1.2.0)
    ```

* Launch xp

1. If you want to use cinder volumes (like amazon EBS, block storage) *you must have deployed the parted image !*

    ```
    ruby bin/openstackg5k -m educ -i ~/kavlan_nodes
    ```

2. Otherwise

    ```
    ruby bin/openstackg5k -m educ -v -i ~/kavlan_nodes
    ```

* Enjoy :-)

    ```

    root@talc-11-kavlan-4:~# nova-manage service list
    Binary           Host                                 Zone             Status     State Updated_At
    nova-consoleauth talc-11-kavlan-4.nancy.grid5000.fr   internal         enabled    :-)   2013-07-10 19:18:32
    nova-scheduler   talc-11-kavlan-4.nancy.grid5000.fr   internal         enabled    :-)   2013-07-10 19:18:32
    nova-conductor   talc-11-kavlan-4.nancy.grid5000.fr   internal         enabled    :-)   2013-07-10 19:18:32
    nova-network     talc-11-kavlan-4.nancy.grid5000.fr   internal         enabled    :-)   2013-07-10 19:18:36
    nova-cert        talc-11-kavlan-4.nancy.grid5000.fr   internal         enabled    :-)   2013-07-10 19:18:32
    nova-compute     talc-33-kavlan-4.nancy.grid5000.fr   nova             enabled    :-)   2013-07-10 19:18:35
    nova-compute     talc-77-kavlan-4.nancy.grid5000.fr   nova             enabled    :-)   2013-07-10 19:18:29
    nova-compute     talc-90-kavlan-4.nancy.grid5000.fr   nova             enabled    :-)   2013-07-10 19:18:27
    nova-compute     talc-76-kavlan-4.nancy.grid5000.fr   nova             enabled    :-)   2013-07-10 19:18:32
    nova-compute     talc-71-kavlan-4.nancy.grid5000.fr   nova             enabled    :-)   2013-07-10 19:18:27
    ```
# Contact

* Sebastien Badia (mail/xmpp : seb _AT_ sebian _DOT_ fr )


# FAQ

* Q: I have this error

      Something went wrong!
      An unexpected error has occurred. Try refreshing the page. If that doesn't help,  contact your local administrator.

* A: Don't panic, just drop your cookies for localhost:8888
