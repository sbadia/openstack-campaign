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
      ensure => installed,
      require => [File["source puppetlabs"],Exec["sources update"]];
  }

  include "apt::allowunauthenticated"

  apt::source {
    "puppetlabs":
      source => "puppet:///modules/puppet/repo/puppetlabs.list",
      unauth => true;
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
  }

  exec {
    "Import puppet key":
      command       => "/bin/cat /root/puppet-gpg.asc | /usr/bin/apt-key add -",
      path          => "/usr/sbin:/bin:/usr/bin",
      unless        => "/usr/bin/apt-key list | /bin/grep Puppet",
      user	  => root,
      require	  => File["/root/puppet-gpg.asc"];
  }
} # Class:: puppet::base

# Class:: puppet::master inherits puppet::base
#
#
class puppet::master inherits puppet::base {
  package {
    ["puppetmaster-passenger","mysql-server","libmysql-ruby","build-essential","libmysqlclient-dev"]:
      ensure => installed,
      require => [File["source puppetlabs"],Exec["sources update"]];
    "mysql":
      ensure => installed,
      provider => gem,
      require => Package["libmysqlclient-dev"];
    "activerecord":
      ensure => "3.0.11",
      provider => gem;
  }

  File["/etc/puppet/puppet.conf"] { source  => "puppet:///modules/puppet/master/puppet.conf" }
} # Class:: puppet::master inherits puppet::base
