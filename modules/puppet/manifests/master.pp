# Module:: puppet
# Manifest:: master.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: 2013-03-11 18:25:24 +0100
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

# Class:: puppet::master inherits puppet
#
#
class puppet::master inherits puppet {

  include 'mysql'

  file {
    '/etc/apache2/sites-available/puppetmaster':
      ensure  => file,
      content => template('modules/puppet/puppetmaster.erb'),
      owner   => root,
      group   => root,
      mode    => '0644',
      notify  => Service['apache2'],
      require => Package['puppetmaster-passenger'];
  }

  service {
    'apache2':
      ensure     => running,
      hasrestart => true,
      hasstatus  => true,
      require    => Package['puppetmaster-passenger'];
  }

  package {
    ['puppetmaster-passenger','libmysql-ruby','libactiverecord-ruby']:
      ensure => installed;
  }

  File['/etc/puppet/puppet.conf'] { source  => 'puppet:///modules/puppet/master/puppet.conf' }

  class { 'mysql::server': }

  mysql::db {
    'puppet':
      ensure   => 'present',
      charset  => 'utf8',
      user     => 'puppet',
      password => 'password',
      host     => 'localhost',
      grant    => ['all'],
      # http://projects.puppetlabs.com/issues/17802
      require  => Class['mysql::config'],
  }

  file {
    '/etc/puppet/manifests/install.pp':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/install.pp',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppetmaster-passenger'];
    '/etc/puppet/manifests/openstack.pp':
      ensure  => file,
      source  => 'puppet:///modules/puppet/master/openstack.pp',
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppetmaster-passenger'];
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
      require => Package['puppetmaster-passenger'];
  }
} # Class:: puppet::master inherits puppet
