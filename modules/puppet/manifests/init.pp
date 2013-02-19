# Module:: puppet
# Manifest:: init.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu May 31 18:36:30 +0200 2012
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

import 'master.pp'
import 'client.pp'

# Class:: puppet
#
#
class puppet {
  package {
    ['rake','git','multitail','ruby']:
      ensure => installed;
  }

  package {
    'puppet':
      ensure  => latest,
      require => Apt::Source['puppetlabs'];
  }

  apt::source {
    'puppetlabs':
      location  => 'http://apt.puppetlabs.com/',
      release   => $lsbdistcodename,
      repos     => 'main',
      key       => '4BD6EC30';
  }

  apt::key {
    'puppetlabs':
      key         => '4BD6EC30',
      key_source  => '/root/puppet-gpg.asc',
      require     => File['/root/puppet-gpg.asc'];
  }

  file {
    '/etc/puppet/puppet.conf':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['puppet'];
    '/root/puppet-gpg.asc':
      ensure  => file,
      source  => 'puppet:///modules/puppet/repo/4BD6EC30.asc',
      owner   => root,
      group   => root,
      mode    => '0644';
    '/etc/gemrc':
      source  => 'puppet:///modules/puppet/repo/gemrc',
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644';
  }
} # Class:: puppet
