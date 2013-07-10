# Openstack-campaign

Work in progress

## Usage

* Reserve nodes using OAR

    ```
    oarsub -t deploy -l {"type='kavlan'"}/vlan=1+/nodes=3,walltime=10:00:00 -r "2013-07-10 09:00:00" -n "openstack"
    ```

* When reservation is running, connect using your job id, and launch deployment

    ```
    oarsub -C <jobid>
    ```
    ```
    kadeploy3 -f $OAR_NODEFILE -e ubuntu-x64-1204 -k --vlan `kavlan -V`
    ```
    ```
    kavlan -l > ~/kavlan_nodes
    ```

* Download lastest openstack-campaign from git, switch to folsom branch (yes folsom for grizzly, i'm not drunk ;-)), fetch puppet modules (from puppet forge)
    ```
    https_proxy=http://proxy:3128 git clone https://github.com/sbadia/openstack-campaign
    ```
    ```
    cd openstack-campaign; git checkout folsom
    ```
    ```
    gem install --no-ri --no-rdoc puppet -v 2.7.14 --user-install
    http_proxy=https://proxy:3128 $HOME/.gem/ruby/1.8/bin/puppet module install puppetlabs/openstack --version 2.0.0 --modulepath $(pwd)/modules
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

    ```
    ruby bin/openstackg5k -m educ -i ~/kavlan_nodes
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
