# Openstack-campaign

Work in progress

## Usage

* Reserve nodes using OAR

    ```oarsub -t deploy -l {"type='kavlan'"}/vlan=1+/nodes=3,walltime=10:00:00 -r "2013-07-10 09:00:00" -n "openstack"```

* When reservation is running, connect using your job id, and launch deployment

    ```oarsub -C <jobid>
    kadeploy3 -f $OAR_NODEFILE -e ubuntu-x64-1204 -k --vlan `kavlan -V`
    kavlan -l > ~/kavlan_nodes```

* Download lastest openstack-campaign from git, switch to folsom branch (yes folsom for grizzly, i'm not drunk ;-)), fetch puppet modules (from puppet forge)

    ```https_proxy=http://proxy:3128 git clone https://github.com/sbadia/openstack-campaign
    cd openstack-campaign; git checkout folsom
    http_proxy=http://proxy:3128 puppet module install puppetlabs/openstack --version 2.0.0 --modulepath $(pwd)/modules```

* Launch xp

    ruby bin/openstack -m educ -i ~/kavlan_nodes


* Enjoy :-)

    ```
    root@graphene-25-kavlan-4:~# nova-manage service list
    Binary           Host                                   Zone             Status  State Updated_At
    nova-consoleauth graphene-25-kavlan-4.nancy.grid5000.fr internal         enabled :-)   2013-07-09 17:43:33
    nova-scheduler   graphene-25-kavlan-4.nancy.grid5000.fr internal         enabled :-)   2013-07-09 17:43:33
    nova-conductor   graphene-25-kavlan-4.nancy.grid5000.fr internal         enabled :-)   2013-07-09 17:43:33
    nova-network     graphene-25-kavlan-4.nancy.grid5000.fr internal         enabled :-)   2013-07-09 17:43:37
    nova-cert        graphene-25-kavlan-4.nancy.grid5000.fr internal         enabled :-)   2013-07-09 17:43:32
    nova-compute     graphene-75-kavlan-4.nancy.grid5000.fr nova             enabled :-)   2013-07-09 17:43:34
    nova-compute     graphene-76-kavlan-4.nancy.grid5000.fr nova             enabled :-)   2013-07-09 17:43:31```


# Contact

* Sebastien Badia (mail/xmpp : seb _AT_ sebian _DOT_ fr )
