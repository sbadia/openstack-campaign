# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:10:10 +0200 2012
#
module Openstackg5k
  $startt = Time::now

  VERSION = "0.0.4"
  MSG_ERROR=0       # Exit return codes
  MSG_WARNING=1
  MSG_INFO=2

  def get_vlan_property(jobid)
    oarprop = nil
    vlans = []
    if not jobid.nil?
      oarprop = IO.popen("/usr/bin/oarstat -p -j "+jobid.to_s).readlines
    else
      $log.error "bad arguments #{jobid}"
      exit 1
    end
    oarprop.each do |prop|
      if prop =~ /vlan\s+\=\s+\'(\d+)\'/
        vlans.push($1)
      end
    end
    if (vlans.length < 1)
      $log.error "no vlan found, default to vlan 5"
      vlans = 5
    else
      return vlans
    end
  end # def:: get_vlan_property(jobid)

  def clean!
    $log.warn "Received cleanup request, killing all jobs and deployments..."
    $deploy.each{|deployment| deployment.delete}
    $jobs.each{|job| job.delete}
  end # def:: clean!


  def time_elapsed
    return (Time::now - $startt).to_i
  end # def:: time_elapsed

  def msg(str, type=nil, quit=false)
    case type
    when MSG_ERROR
      puts("### Error: #{str} ###")
    when MSG_WARNING
      puts("### Warning: #{str} ###")
    when MSG_INFO
      puts("[#{(Time.now - $startt).to_i}] #{str}")
    else
      puts str
    end
    exit 1 if quit
  end # def:: msg

  def open_channel(session, group = nil)
    if group.is_a?(Symbol)
      session.with(group).open_channel do |channel|
        yield(channel)
      end
    elsif group.is_a?(Array)
      session.on(*group).open_channel do |channel|
        yield(channel)
      end
    elsif group.is_a?(Net::SSH::Multi::Server)
      session.on(group).open_channel do |channel|
        yield(channel)
      end
    else
      session.open_channel do |channel|
        yield(channel)
      end
    end
  end # def:: open_channel

  def nexec(session, cmd, group = nil, critical = true, showerr = true, showout = true)
    outs = {}
    errs = {}
    channel = open_channel(session,group) do |chtmp|
      chtmp.exec(cmd) do |ch, success|
        unless success
          msg("unable to execute '#{cmd}' on #{ch.connection.host}",MSG_ERROR)
        end
          msg("Executing '#{cmd}' on #{ch.connection.host}]",MSG_INFO) \
          if showout
      end
    end
    channel.on_data do |chtmp,data|
      outs[chtmp.connection.host] = [] unless outs[chtmp.connection.host]
      outs[chtmp.connection.host] << data.strip
      msg("[#{chtmp.connection.host}] #{data.strip}") \
      if showout
    end
    channel.on_extended_data do |chtmp,type,data|
      errs[chtmp.connection.host] = [] unless errs[chtmp.connection.host]
      errs[chtmp.connection.host] << data.strip
      msg("[#{chtmp.connection.host} E] #{data.strip}") \
        if showout
    end

    channel.on_request("exit-status") do |chtmp, data|
      status = data.read_long
      if status != 0
        if showerr or critical
          msg("exec of '#{cmd}' on #{chtmp.connection.host} failed " \
              "with return status #{status.to_s}",MSG_ERROR)
          msg("---stdout dump---")
          outs[chtmp.connection.host].each { |out| msg(out) } if \
            outs[chtmp.connection.host]
          msg("---stderr dump---")
          errs[chtmp.connection.host].each { |err| msg(err) } if \
            errs[chtmp.connection.host]
          msg("---\n")
        end
        exit 1 if critical
      end
    end
    channel.wait
    return outs
  end # def:: nexec

  def generate_site(nodesite)
    puppet = nodesite.shift
    clients = nodesite
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/site.pp'),"w")
    f.puts <<-EOF
# MANAGED BY PUPPET
Exec {
  logoutput => true,
}

node '#{puppet}' {
  include 'puppet::master'
  class { 'openstack::controller':
    public_address   => $fqdn,
    public_interface => 'eth0',
    private_interface => 'eth0',
    internal_address => $ipaddress,
  }
  class { 'openstack_controller': }
}


node '#{clients.join('\',\'')}' {
    $master = '#{puppet}'
    include 'puppet::client'

    class { 'openstack::compute':
      internal_address => $ipaddress,
      private_interface => 'eth0',
    }
}

class openstack_controller {
  #
  # set up auth credntials so that we can authenticate easily
  #
  file { '/root/auth':
    content =>
  '
  export OS_TENANT_NAME=openstack
  export OS_USERNAME=admin
  export OS_PASSWORD=ChangeMe
  export OS_AUTH_URL="http://localhost:5000/v2.0/"
  '
  }
  # this is a hack that I have to do b/c openstack nova
  # sets up a route to reroute calls to the metadata server
  # to its own server which fails
  file { '/usr/lib/ruby/1.8/facter/ec2.rb':
    ensure => absent,
  }

  class {
    'openstack::auth_file':
      admin_password => 'ChangeMe';
  }
} # class openstack_controller
EOF
  f.close
  end # def:: generate_site(nodes)

  def autosign_puppet(sign)
    f = File.new(File.join(File.expand_path(File.dirname(__FILE__)),'..','/modules/puppet/files/master/autosign.conf'),"w")
      sign.each do |n|
        f.puts n
      end
    f.close
  end # def:: autosign_puppet(sign)
end # module:: Openstackg5k
