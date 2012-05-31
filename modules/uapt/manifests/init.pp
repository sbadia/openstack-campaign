# Module:: apt
# Manifest:: init.pp
#
# Author:: Pascal Morillon    (<pascal.morillon@irisa.fr>)
# Author:: Remi Palancher     (<remi.palancher@inria.fr>)
# Author:: Sebastien Varrette (<sebastien.varrette@uni.lu>)
# Date:: Mon Oct 12 15:48:42 +0200 2009
# Maintainer:: Pascal Morillon (<pascal.morillon@irisa.fr>)
#

# Class uapt
#
#
class uapt {
  Package {
    require => Exec["sources update"]
  }

  exec { "sources update":
      command => "apt-get update",
      path => "/usr/bin:/usr/sbin:/bin",
      refreshonly => true;
  }
}

# Class uapt::allowunauthenticated
#
#
class uapt::allowunauthenticated inherits uapt {

  file { "Apt allow unauthenticated":
      path => "/etc/apt/apt.conf.d/allow-unauthenticated",
      ensure => file,
      mode => 644, owner => root, group => root,
      content => "APT::Get::AllowUnauthenticated \"true\";\n";
  }

}

# Define: apt::proxy
# Parameters:
# $ensure
#
define uapt::proxy ($ensure) {
  file {
    "/etc/apt/apt.conf.d/proxy-guess":
      ensure => $ensure,
      mode => 644, owner => root, group => root,
      content => "Acquire::http::Proxy \"$name\";\n";
  }
}

# Define: uapt::source
# Create a new file /etc/apt/sources.list.d/${name}.list
# Parameters:
# $source
# $content
# $unauth
#
define uapt::source (
  $source  = false,
  $content = false,
  $unauth  = false) {

    if $source {
      file { "source $name":
        path => "/etc/apt/sources.list.d/$name.list",
        ensure => file,
        mode => 644,
        owner => root,
        group => root,
        source => $source,
        before => Exec["sources update"],
        notify => Exec["sources update"],
      }
    } else {
      file { "source $name":
        path => "/etc/apt/sources.list.d/$name.list",
        ensure => file,
        mode => 644,
        owner => root,
        group => root,
        content => $content,
        before => Exec["sources update"],
        notify => Exec["sources update"],
      }
    }

    if $unauth == true {
      File["source $name"] {
        require +> File["Apt allow unauthenticated"]
      }
    }
}
