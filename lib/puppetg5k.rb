# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu Jun 07 19:12:44 +0200 2012
#
module Puppetg5k
  def generate_site(nodesite)
    puppet = nodesite.shift
    clients = nodesite
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/site.pp'),"w")
    f.puts <<-EOF
# MANAGED BY PUPPET
Exec {
  logoutput => true,
}

node '#{puppet}' {
  include 'puppet::master'
  class { 'openstack::controller':
    public_address   => $fqdn,
    public_interface => 'eth0',
    private_interface => 'eth0',
    internal_address => $ipaddress,
  }
  class { 'openstack_controller': }
}


node '#{clients.join('\',\'')}' {
    $master = '#{puppet}'
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
EOF
  f.close
  end # def:: generate_site(nodes)

  def autosign_puppet(sign)
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/autosign.conf'),"w")
      sign.each do |n|
        f.puts n
      end
    f.close
  end # def:: autosign_puppet(sign)
end # module:: Puppetg5k
