#!/usr/bin/env ruby
# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:22:33 +0200 2012
#

$: << File.join(File.dirname(__FILE__), "..", "lib")

require 'openstackg5k'
require 'puppetg5k'
require 'rubygems'
require 'mixlib/cli'
require 'restfully'
require 'net/ssh'
require 'net/scp'
require 'net/ssh/multi'
require 'json'
require 'yaml'

include Openstackg5k
include Puppetg5k

class Openstack
  include Mixlib::CLI

  option :config_file,
    :short        => "-c CONFIG",
    :long         => "--config CONFIG",
    :default      => "openstackg5k.yml",
    :description  => "The configuration file to use"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log-level LEVEL",
    :description  => "Set log level (debug, info, warn, error, fatal)",
    :default      => "warn",
    :proc         => Proc.new { |l| l.to_sym }

  option :no_clean,
    :short        => "-n",
    :long         => "--no-clean",
    :description  => "Disable restfully clean (jobs/deploy)",
    :boolean      => true

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
    $log = Logger.new(STDOUT)
    #$log.level = Logger::config[:log_level].to_s.upcase
    $log.level = Logger::INFO
    $jobs = []
    $deploy = []

    %w{INT TERM}.each do |sig|
      Signal.trap(sig){
        Openstackg5k::clean!
        exit(1)
      }
    end
    launch_os
  end # def:: runos

  def launch_os
    if File.exist?(config[:config_file])
      conf = YAML.load_file(config[:config_file])
      $log.info "Use config file #{config[:config_file]}"
    else
      $log.error "No conf file"
      exit 1
    end

    begin
      Restfully::Session.new(:logger => $log, :cache => conf['cache'], :base_uri => conf['base_uri']) do |root,rsession|
        site = root.sites[:"#{conf['site']}"]
        if site.status.find{ |node| node['system_state'] == 'free' && node['hardware_state'] == 'alive' } then
          rsession.logger.info "Job: #nodes => #{conf['nodes']}, type => {type='kavlan'}/vlan=1"
          new_job = site.jobs.submit(
            :resources => "{type='kavlan'}/vlan=1+/nodes=#{conf['nodes']},walltime=#{conf['walltime_hours']}",
            :command => "sleep #{(conf['walltime_hours'].to_i)*7200}",
            :types => ["deploy"],
            :name => conf['job_name']) rescue nil
          $jobs.push(new_job) unless new_job.nil?
        else
          rsession.logger.warn "No enough free node on #{conf['site']} site"
          exit 1
        end

        if $jobs.empty?
          rsession.logger.error "No jobs, quit..."
          exit 0
        end

        begin
          Timeout.timeout(120) do
            until $jobs.all?{|job| job.reload['state'] == 'running' } do
              rsession.logger.info "Some jobs are not running, wait before checking..."
              sleep 4
            end
          end
        rescue Timeout::Error => e
          rsession.logger.warn "One of the jobs is still not running..."
        end

        $jobs.each do |job|
          next if job.reload['state'] != 'running'
          $vlan = Openstackg5k::get_vlan_property(job['uid'])
          rsession.logger.info "Deploy: env => #{conf['env']}, nodes => #{job["assigned_nodes"]}, vlan => #{$vlan.to_s}"
          new_deploy = job.parent.deployments.submit(:environment => conf['env'], :nodes => job['assigned_nodes'], :key => File.read(conf['key']), :vlan => $vlan.to_s) rescue nil
          $deploy.push(new_deploy) unless new_deploy.nil?
        end

        begin
          Timeout.timeout(900) do
            until $deploy.all?{ |deployment| deployment.reload['status'] != 'processing' } do
              rsession.logger.info "Some deployments are not terminated. Waiting before checking again..."
              sleep 30
            end
          end
        rescue Timeout::Error => e
          rsession.logger.warn "One of the deployments is still not terminated, it will be discarded."
        end

        $deploy.each do |deployment|
          next if deployment.reload['status'] != 'terminated'
          good = []
          deployment['nodes'].each do |conv|
            good << "#{conv.split('.')[0]}-kavlan-#{$vlan.to_s}.#{conf['site']}.grid5000.fr"
          end
          nodes = good.dup
          Puppetg5k::clush_nodes(good)
          Puppetg5k::generate_site(good)
          Puppetg5k::autosign_puppet(good)
          ctrl = nodes.shift
          Net::SSH::Multi.start(:on_error => :warn) do |session|
            good.each do |node|
              session.use "root@#{node}"
            end
            session.group :compute do
              nodes.each do |cmp|
                session.use "root@#{cmp}"
              end
            end
            session.group :cloud do
              ctrl.each do |ctr|
                session.use "root@#{ctr}"
              end
            end
            # nexec(session, cmd, args = {:group => nil, :critical => true, :showerr => true, :showout => true})
            Openstackg5k::nexec(session,"rm -f /etc/ldap/ldap.conf;apt-get update;apt-get install rake puppet git multitail -y --force-yes", args = {:showout => true})
            session.loop
            good.each do |nod|
              rsession.logger.info "Upload puppet modules on #{nod}..."
              system("rsync --numeric-ids --archive --bwlimit=100000 --rsh ssh #{File.join('./',File.dirname(__FILE__),'..','modules')} root@#{nod}:/etc/puppet")
            end
            Openstackg5k::nexec(session,"puppet apply --modulepath /etc/puppet/modules /etc/puppet/modules/puppet/files/master/openstack.pp",args = { :critical => true, :showout => true})
            session.loop
          end # Net::SSH::Multi
        end # $deploy.each
      end # Restfully::Session
    rescue => e
      $log.error "Catched unexpected exception #{e.class.name}: #{e.message} - #{e.backtrace.join("\n")}"
      if ! config[:no_clean].nil?:
        Openstackg5k::clean!
      end
      exit 1
    end
  end # def:: launch_os
end # class:: Openstackg5k

openstack = Openstack.new
openstack.runos
