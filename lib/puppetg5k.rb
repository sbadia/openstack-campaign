# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu Jun 07 19:12:44 +0200 2012
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
    $master = '#{puppet}'
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


# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments

# assumes that eth0 is the public interface
$public_interface  = 'br100'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface = 'br100'
# credentials
$admin_email          = 'seb@sebian.fr'
$admin_password       = 'keystone_admin'
$keystone_db_password = 'keystone_db_pass'
$keystone_admin_token = 'keystone_admin_token'
$nova_db_password     = 'nova_pass'
$nova_user_password   = 'nova_pass'
$glance_db_password   = 'glance_pass'
$glance_user_password = 'glance_pass'
$rabbit_password      = 'openstack_rabbit_password'
$rabbit_user          = 'openstack_rabbit_user'
$fixed_network_range  = '10.0.0.0/20'
# switch this to true to have all service log at verbose
$verbose              = 'false'


#### end shared variables #################

# multi-node specific parameters

$controller_node_public   = '#{puppet}'
$controller_node_internal = '#{puppet}'
$sql_connection         = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"

node '#{puppet}' {

#  class { 'nova::volume': enabled => true }
#  class { 'nova::volume::iscsi': }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
    floating_range          => '10.16.60.0/24',
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => false,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatManager',
    verbose                 => $verbose,
    mysql_root_password     => $mysql_root_password,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    export_resources        => false,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }


}

node '#{clients.join('\',\'')}' {

  class { 'openstack::compute':
    private_interface  => $private_interface,
    internal_address   => $ipaddress,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatManager',
    multi_host         => false,
    sql_connection     => $sql_connection,
    rabbit_host        => $controller_node_internal,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => "${controller_node_internal}:9292",
    vncproxy_host      => $controller_node_public,
    vnc_enabled        => 'true',
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes'
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
