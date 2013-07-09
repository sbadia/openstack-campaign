# Module:: puppet
# Manifest:: init.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: 2013-03-11 18:25:24 +0100
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

import 'master.pp'
import 'client.pp'

# Class:: puppet
#
#
class puppet {
  package {
    ['rake','git','multitail','ruby','htop','strace','dstat']:
      ensure => installed;
  }

  file {
    '/etc/puppet/puppet.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644';
    '/etc/gemrc':
      ensure  => file,
      source  => 'puppet:///modules/puppet/repo/gemrc',
      owner   => root,
      group   => root,
      mode    => '0644';
  }

  # OpenStack Grizzly pre
  package {
    ['ubuntu-cloud-keyring','python-software-properties',
      'software-properties-common','python-keyring']:
      ensure => installed;
  }

  file {
    '/etc/apt/sources.list.d/grizzly.list':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => 'deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/grizzly main';
  }

  # Remove Grid'5000 settings
  file {
    '/etc/ldap/ldap.conf':
      ensure => absent;
  }
} # Class:: puppet
