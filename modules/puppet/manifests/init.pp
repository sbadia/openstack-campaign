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

  file {
    '/etc/gemrc':
      source  => 'puppet:///modules/puppet/repo/gemrc',
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644';
  }
} # Class:: puppet
