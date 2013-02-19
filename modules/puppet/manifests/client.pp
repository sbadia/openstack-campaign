# Module:: puppet
# Manifest:: client.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Thu May 31 18:36:30 +0200 2012
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

# Class:: puppet::client
#
#
class puppet::client {
  require 'puppet'

  #include 'custom'
  #line {
  #  puppetmaster:
  #    file => '/etc/puppet/puppet.conf',
  #    line => 'server = $master';
  #}

  File['/etc/puppet/puppet.conf'] { content  => template('puppet/client.conf.erb') }

} # Class:: puppet::client
