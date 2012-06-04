#!/usr/bin/env ruby
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:22:33 +0200 2012
#

$: << File.join(File.dirname(__FILE__), "..", "lib")

require 'openstackg5k'
require 'rubygems'
require "mixlib/cli"
require 'restfully'
require 'json'
require 'yaml'

class Openstack
  include Mixlib::CLI

  option :config_file,
    :short        => "-c CONFIG",
    :long         => "--config CONFIG",
    :default      => 'openstackg5k.yml',
    :description  => "The configuration file to use"

  option :debug,
    :short        => "-d",
    :long         => "--debug",
    :description  => "Active debug mode",
    :boolean      => true,
    :proc         => nil

  option :help,
    :short        => "-h",
    :long         => "--help",
    :description  => "Show this message",
    :on           => :tail,
    :boolean      => true,
    :show_options => true,
    :exit         => 0

  option :version,
    :short        => "-v",
    :long         => "--version",
    :description  => "Show mkmotd version",
    :boolean      => true,
    :proc         => lambda {|v| puts Openstackg5k::VERSION},
    :exit         => 0

  def runos
    parse_options
    launch_os
  end # def:: runos

  def get_vlan_property(jobid)
    oarprop = nil
    vlans = []
    if not jobid.nil?
      oarprop = IO.popen("/usr/bin/oarstat -p -j "+jobid.to_s).readlines
    else
      puts "bad arguments #{jobid}"
      exit 1
    end
    oarprop.each do |prop|
      if prop =~ /vlan\s+\=\s+\'(\d+)\'/
        vlans.push($1)
      end
    end
    if (vlans.length < 1)
      puts "no vlan found"
      exit 1
    else
      return vlans
    end
  end # def:: get_vlan_property(jobid)

  def launch_os
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    #conf = YAML.load_file(config[:config_file])

    logger.info "Use config file #{config[:config_file]}"

  end # def:: launch_os
end # class:: Openstackg5k

#job = root.sites[:nancy].jobs.submit(:resources => "{type='kavlan'}/vlan=1+/nodes=1",:command => "sleep 7200",:types => ["deploy"],:name => "test")
#pp job['uid']

openstack = Openstack.new
openstack.runos
