# Module:: puppet
# Manifest:: client.pp
#
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: 2013-03-11 18:25:24 +0100
# Maintainer:: Sebastien Badia (<seb@sebian.fr>)
#

# Class:: puppet::client inherits puppet
#
#
class puppet::client inherits puppet {

  File['/etc/puppet/puppet.conf'] {
    content  => template('puppet/client.conf.erb')
  }

} # Class:: puppet::client inherits puppet::base
