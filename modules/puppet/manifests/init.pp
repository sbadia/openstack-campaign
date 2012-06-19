# Module:: puppet
# Manifest:: init.pp
#
# Author:: Sebastien Badia (<sebastien.badia@inria.fr>)
# Date:: Thu May 31 18:36:30 +0200 2012
# Maintainer:: Sebastien Badia (<sebastien.badia@inria.fr>)
#

# Class:: puppet::base
#
#
class puppet::base {
  package {
    ["rake","git","multitail"]:
      ensure => installed;
  }

  package {
    "puppet":
      ensure => installed;
  }

  apt::source {
    "puppetlabs":
      location => "http://apt.puppetlabs.com/",
      release => $lsbdistcodename,
      repos => "main",
      key => "4BD6EC30";
  }

  apt::key {
    "puppetlabs":
      key => "4BD6EC30",
      key_source => "/root/puppet-gpg.asc",
      require => File["/root/puppet-gpg.asc"];
  }

  file {
    "/etc/puppet/puppet.conf":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      require => Package["puppet"];
    "/root/puppet-gpg.asc":
      source  => "puppet:///modules/puppet/repo/4BD6EC30.asc",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
    "/etc/gemrc":
      source  => "puppet:///modules/puppet/repo/gemrc",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644;
  }
} # Class:: puppet::base

# Class:: puppet::master inherits puppet::base
#
#
class puppet::master inherits puppet::base {
  package {
    ["puppetmaster","libmysql-ruby","build-essential","libmysqlclient-dev"]:
      ensure => installed;
    "mysql":
      ensure => installed,
      provider => gem,
      require => [Package["libmysqlclient-dev"],File["/etc/gemrc"]];
    "activerecord":
      ensure => "3.0.11",
      provider => gem,
      require => File["/etc/gemrc"];
  }

  File["/etc/puppet/puppet.conf"] { source  => "puppet:///modules/puppet/master/puppet.conf" }

  mysql::db {
    "puppet":
      user => 'puppet',
      password => 'puppet',
      host => 'localhost',
      grant => ['all'];
   }

  file {
    "/etc/puppet/manifests/install.pp":
      source  => "puppet:///modules/puppet/master/install.pp",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      require => Package["puppetmaster"];
    "/etc/puppet/manifests/openstack.pp":
      source  => "puppet:///modules/puppet/master/openstack.pp",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      require => Package["puppetmaster"];
    "/etc/puppet/manifests/site.pp":
      ensure  => link,
      target  => "/etc/puppet/manifests/openstack.pp",
      require => File["/etc/puppet/manifests/openstack.pp"];
    "/etc/puppet/autosign.conf":
      source  => "puppet:///modules/puppet/master/autosign.conf",
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => 644,
      require => Package["puppetmaster"];
  }
} # Class:: puppet::master inherits puppet::base

# Class:: puppet::client inherits puppet::base
#
#
class puppet::client inherits puppet::base {
  #include 'custom'
  #line {
  #  puppetmaster:
  #    file => "/etc/puppet/puppet.conf",
  #    line => "server = $master";
  #}

  File["/etc/puppet/puppet.conf"] { content  => template("puppet/client.conf.erb") }
} # Class:: puppet::client inherits puppet::base
