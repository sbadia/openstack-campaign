# Module:: puppet
# Manifest:: master.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu May 31 18:36:30 +0200 2012
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

# Class:: puppet::master
#
#
class puppet::master {
  require 'puppet'

  package {
    ['puppetmaster','libmysql-ruby','build-essential',
    'libmysqlclient-dev','libactiverecord-ruby']:
      ensure    => installed;
  }

  file {
    '/etc/puppet/puppet.conf':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/puppet.conf',
      owner   => root,
      group   => root,
      mode    => '0644';
  }

  include 'mysql'

  class { 'mysql::server': }

  mysql::db {
    'puppet':
      user     => 'puppet',
      password => 'puppet',
      host     => 'localhost',
      grant    => ['all'],
      require  => Class['mysql::config'],
   }

  file {
    '/etc/puppet/manifests/install.pp':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/install.pp',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppetmaster'];
    '/etc/puppet/manifests/openstack.pp':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/openstack.pp',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppetmaster'];
    '/etc/puppet/manifests/site.pp':
      ensure  => link,
      target  => '/etc/puppet/manifests/openstack.pp',
      require => File['/etc/puppet/manifests/openstack.pp'];
    '/etc/puppet/autosign.conf':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/autosign.conf',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppetmaster'];
  }
} # Class:: puppet::master
