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
    ['rake','git','multitail']:
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
} # Class:: puppet
