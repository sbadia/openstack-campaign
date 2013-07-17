# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu Jun 07 19:12:44 +0200 2012
# vi: set ft=ruby :
#
module Puppetg5k
  def generate_site(nodesite)
    pnodes = nodesite.dup
    puppet = pnodes.shift
    clients = pnodes
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/install.pp'),"w")
    f.puts <<-EOF
# MANAGED BY PUPPET
node '#{puppet}' {
  include 'mysql::server'
  include 'puppet::master'
}


node '#{clients.join('\',\'')}' {
    $masterg5k = '#{puppet}'
    include 'puppet::client'
}
EOF

  f.close
  p = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/openstack.pp'),"w")
  p.puts <<-EOF
# MANAGED BY PUPPET
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.
#

# deploy a script that can be used to test nova
file {
  "/tmp/nova.sh":
    source  => "puppet:///modules/puppet/nova_test.sh",
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 0755;
}
####### shared variables ##################
$controller_node_public   = '#{puppet}'
$controller_node_internal = '#{puppet}'
$fixed_network_range      = '10.0.0.0/20'
$admin_email              = 'seb@fooboozoo.fr'
$password                 = 'changeme'
$keystone_admin_token     = 'keystone_admin_token'
$secret_key               = 'QnXN1eEQsBC7w'
$db_pass                  = 'changeme'
#### end shared variables #################

node '#{puppet}' {
  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => 'br100',
    private_interface       => 'br100',
    internal_address        => $controller_node_internal,
    floating_range          => '10.16.60.0/24',
    fixed_range             => $fixed_network_range,
    mysql_root_password     => 'password',
    multi_host              => false,
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    admin_email             => $admin_email,
    admin_password          => $password,
    keystone_admin_token    => $keystone_admin_token,
    keystone_db_password    => $password,
    glance_db_password      => $password,
    nova_db_password        => $password,
    cinder_db_password      => $password,
    quantum                 => false,
    glance_user_password    => $password,
    nova_user_password      => $password,
    cinder_user_password    => $password,
    rabbit_password         => $password,
    rabbit_user             => $rabbit_user,
    secret_key              => $secret_key,
  }

  class { 'openstack::auth_file':
    admin_password       => $password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }


}

node '#{clients.join('\',\'')}' {

  class { 'openstack::compute':
    private_interface     => 'br100',
    internal_address      => $ipaddress_br100,
    libvirt_type          => 'kvm',
    quantum               => false,
    fixed_range           => $fixed_network_range,
    network_manager       => 'nova.network.manager.FlatDHCPManager',
    rabbit_host           => $controller_node_internal,
    rabbit_password       => $password,
    rabbit_user           => $rabbit_user,
    cinder_db_password    => $password,
    db_host               => $controller_node_internal,
    glance_api_servers    => "${controller_node_internal}:9292",
    vncproxy_host         => $controller_node_public,
    vnc_enabled           => 'true',
    nova_user_password    => $password,
    nova_db_password      => $password,
    manage_volumes        => true,
  }

}
EOF
  p.close
  end # def:: generate_site(nodes)

  def autosign_puppet(sign)
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/autosign.conf'),"w")
      sign.each do |n|
        f.puts n
      end
    f.close
  end # def:: autosign_puppet(sign)

  def clush_nodes(cnodes)
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','nodes'),'w')
      f.puts '# clush -l root -w $(nodeset -f $(cat nodes)) "puppetd -t --server=$(cat nodes |head -1)"'
      cnodes.each do |n|
        f.puts n
      end
    f.close
  end # def:: clush_nodes(cnodes)
end # module:: Puppetg5k
