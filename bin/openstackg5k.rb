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
  option :base_uri,
    :short        => "-u URI",
    :long         => "--uri URI",
    :description  => "API Base URI (default: stable API)",
    :default      => "https://api.grid5000.fr/stable/grid5000"

  option :nodes,
    :short        => "-n NUM Nodes",
    :long         => "--nodes Num Nodes",
    :description  => "Number of nodes (default: 4)",
    :default      => 4

  option :walltime,
    :short        => "-w WALLTIME",
    :long         => "--walltime WALLTIME",
    :description  => "Walltime of the job (default: 2) hours",
    :default      => "02:00:00"

  option :site,
    :short        => "-s SITE",
    :long         => "--site SITE",
    :description  => "Site to launch job (default: #{%x[hostname -f].split('.')[1]})",
    :default      => "#{%x[hostname -f].split('.')[1]}"

  option :job_name,
    :short        => "-j JOB_NAME",
    :long         => "--name JOB_NAME",
    :description  => "The name of the job (default: openstackg5k)",
    :default      => "openstackg5k"

  option :env,
    :short        => "-e ENV_NAME",
    :long         => "--env ENV_NAME",
    :description  => "Name of then environment to deploy (default: ubuntu-x64-br@sbadia)",
    :default      => "ubuntu-x64-br@sbadia"

  option :key,
    :short        => "-k KEY",
    :long         => "--key KEY",
    :description  => "Name of then SSH key for the deployment (default: /home/sbadia/.ssh/id_dsa.pub)",
    :default      => "/home/sbadia/.ssh/id_dsa.pub"

  option :log_level,
    :short        => "-l LEVEL",
    :long         => "--log-level LEVEL",
    :description  => "Set log level (debug, info, warn, error, fatal)",
    :default      => "warn"

  option :no_clean,
    :short        => "-c",
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
    :description  => "Show Openstackg5k version",
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
    begin
      Restfully::Session.new(:logger => $log, :cache => false, :base_uri => config[:base_uri]) do |root,rsession|
        site = root.sites[:"#{config[:site]}"]
        if site.status.find{ |node| node['system_state'] == 'free' && node['hardware_state'] == 'alive' } then
          rsession.logger.info "Job: #nodes => #{config[:nodes]}, type => {type='kavlan'}/vlan=1"
          new_job = site.jobs.submit(
            :resources => "{type='kavlan'}/vlan=1+/nodes=#{config[:nodes]},walltime=#{config[:walltime]}",
            :command => "sleep #{(config[:walltime].to_i)*7200}",
            :types => ["deploy"],
            :name => config[:job_name]) rescue nil
          $jobs.push(new_job) unless new_job.nil?
        else
          rsession.logger.warn "No enough free node on #{config[:site]} site"
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
          rsession.logger.info "Deploy: env => #{config[:env]}, nodes => #{job["assigned_nodes"]}, vlan => #{$vlan.to_s}"
          new_deploy = job.parent.deployments.submit(:environment => config[:env], :nodes => job['assigned_nodes'], :key => File.read(config[:key]), :vlan => $vlan.to_s) rescue nil
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
            good << "#{conv.split('.')[0]}-kavlan-#{$vlan.to_s}.#{config[:site]}.grid5000.fr"
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
            Openstackg5k::nexec(session,"/etc/init.d/nova-compute restart",args = { :group => :compute, :critical => false, :showout => true})
            session.loop
            Openstackg5k::nexec(session,"bash /etc/puppet/modules/puppet/files/master/finish.sh",args = { :group => :cloud, :critical => false, :showout => true})
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
