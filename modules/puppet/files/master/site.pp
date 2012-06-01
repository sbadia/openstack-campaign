# MANAGED BY PUPPET
Exec {
  logoutput => true,
}

node 'griffon-83-kavlan-4.nancy.grid5000.fr' {
  include 'puppet::master'
  class { 'openstack::controller':
    public_address   => $fqdn,
    public_interface => 'eth0',
    private_interface => 'eth0',
    internal_address => $ipaddress,
  }
  class { 'openstack_controller': }
}


node 'griffon-85-kavlan-4.nancy.grid5000.fr','griffon-87-kavlan-4.nancy.grid5000.fr','griffon-88-kavlan-4.nancy.grid5000.fr','griffon-9-kavlan-4.nancy.grid5000.fr','griffon-90-kavlan-4.nancy.grid5000.fr' {
    $master = 'griffon-83-kavlan-4.nancy.grid5000.fr'
    include 'puppet::client'

    class { 'openstack::compute':
      internal_address => $ipaddress,
      private_interface => 'eth0',
    }
}

class openstack_controller {
  #
  # set up auth credntials so that we can authenticate easily
  #
  file { '/root/auth':
    content =>
  '
  export OS_TENANT_NAME=openstack
  export OS_USERNAME=admin
  export OS_PASSWORD=ChangeMe
  export OS_AUTH_URL="http://localhost:5000/v2.0/"
  '
  }
  # this is a hack that I have to do b/c openstack nova
  # sets up a route to reroute calls to the metadata server
  # to its own server which fails
  file { '/usr/lib/ruby/1.8/facter/ec2.rb':
    ensure => absent,
  }

  class {
    'openstack::auth_file':
      admin_password => 'ChangeMe';
  }
} # class openstack_controller
