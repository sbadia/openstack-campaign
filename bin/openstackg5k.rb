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

  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger::INFO

  def runos
    parse_options
    $jobs = []
    $deploy = []

    def clean!
      LOGGER.warn "Received cleanup request, killing all jobs and deployments..."
      $deploy.each{|deployment| deployment.delete}
      $jobs.each{|job| job.delete}
    end # def:: clean!

    %w{INT TERM}.each do |sig|
      Signal.trap(sig){
        clean!
        exit(1)
      }
    end
    launch_os
  end # def:: runos

  def get_vlan_property(jobid)
    oarprop = nil
    vlans = []
    if not jobid.nil?
      oarprop = IO.popen("/usr/bin/oarstat -p -j "+jobid.to_s).readlines
    else
      LOGGER.error "bad arguments #{jobid}"
      exit 1
    end
    oarprop.each do |prop|
      if prop =~ /vlan\s+\=\s+\'(\d+)\'/
        vlans.push($1)
      end
    end
    if (vlans.length < 1)
      LOGGER.error "no vlan found, default to vlan 5"
      vlans = 5
    else
      return vlans
    end
  end # def:: get_vlan_property(jobid)

  def launch_os
    if File.exist?(config[:config_file])
      conf = YAML.load_file(config[:config_file])
      LOGGER.info "Use config file #{config[:config_file]}"
    else
      LOGGER.error "No conf file"
      exit 1
    end

    begin
      Restfully::Session.new(:logger => LOGGER, :base_uri => conf['base_uri']) do |root,session|
        site = root.sites[:"#{conf['site']}"]
        if site.status.find{ |node| node['system_state'] == 'free' && node['hardware_state'] == 'alive' } then

          new_job = site.jobs.submit(:resources => "{type='kavlan'}/vlan=1+/nodes=#{conf['nodes']}",:command => "sleep 7200", :types => ["deploy"], :name => "openstackg5k") rescue nil
          $jobs.push(new_job) unless new_job.nil?
        else
          session.logger.warn "No enough free node on #{conf['site']} site"
          exit 1
        end

        if $jobs.empty?
          session.logger.error "No jobs, quit..."
          exit 0
        end

        begin
          Timeout.timeout(120) do
            until $jobs.all?{|job| job.reload['state'] == 'running' } do
              session.logger.info "Some jobs are not running, wait before checking..."
              sleep 4
            end
          end
        rescue Timeout::Error => e
          session.logger.warn "One of the jobs is still not running..."
        end

        $jobs.each do |job|
          next if job.reload['state'] != 'running'
          vlan = get_vlan_property(job['uid'])
          session.logger.info "Use KaVLAN vlan #{vlan.to_s}"
          new_deploy = job.parent.deployments.submit(:environment => conf['env'], :nodes => job['assigned_nodes'], :key => File.read(conf['key']), :vlan => vlan.to_s) rescue nil
          $deploy.push(new_deploy) unless new_deploy.nil?
        end

        begin
          Timeout.timeout(900) do
            until $deploy.all?{ |deployment| deployment.reload['status'] != 'processing' } do
              session.logger.info "Some deployments are not terminated. Waiting before checking again..."
              sleep 30
            end
          end
        rescue Timeout::Error => e
          session.logger.warn "One of the deployments is still not terminated, it will be discarded."
        end

        $deploy.each do |deployment|
          next if deployment.reload['status'] != 'terminated'
          deployment['nodes'].each do |host|
            puts "Connecting to #{host} and running..."
            # ssh
          end
        end
      end # Restfully::Session
    rescue => e
      LOGGER.error e.class.name
      clean!
      exit 1
    end
  end # def:: launch_os
end # class:: Openstackg5k

openstack = Openstack.new
openstack.runos
