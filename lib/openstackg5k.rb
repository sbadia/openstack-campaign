# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:10:10 +0200 2012
#
module Openstackg5k
  $startt = Time::now

  VERSION = "0.0.5"
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

  def nexec(session, cmd, args = {:group => nil, :critical => true, :showerr => true, :showout => true})
    outs = {}
    errs = {}
    channel = open_channel(session,args[:group]) do |chtmp|
      chtmp.exec(cmd) do |ch, success|
        unless success
          msg("unable to execute '#{cmd}' on #{ch.connection.host}",MSG_ERROR)
        end
          msg("Executing '#{cmd}' on #{ch.connection.host}]",MSG_INFO) \
          if args[:showout]
      end
    end
    channel.on_data do |chtmp,data|
      outs[chtmp.connection.host] = [] unless outs[chtmp.connection.host]
      outs[chtmp.connection.host] << data.strip
      msg("[#{chtmp.connection.host}] #{data.strip}") \
      if args[:showout]
    end
    channel.on_extended_data do |chtmp,type,data|
      errs[chtmp.connection.host] = [] unless errs[chtmp.connection.host]
      errs[chtmp.connection.host] << data.strip
      msg("[#{chtmp.connection.host} E] #{data.strip}") \
        if args[:showout]
    end

    channel.on_request("exit-status") do |chtmp, data|
      status = data.read_long
      if status != 0
        if args[:showerr] or args[:critical]
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
        exit 1 if args[:critical]
      end
    end
    channel.wait
    return outs
  end # def:: nexec
end # module:: Openstackg5k
