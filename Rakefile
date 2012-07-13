# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:11:30 +0200 2012
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'lib/openstackg5k'
require 'yaml'

GEM = 'openstackg5k'
GEM_VERSION = Openstackg5k::VERSION
TDIR = File.expand_path(File.dirname(__FILE__))

gemspec = Gem::Specification.new do |s|
  s.name          = GEM
  s.version       = GEM_VERSION
  s.platform      = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.extra_rdoc_files  = ["README.md"]
  s.summary           = "A tool for deploy openstack on Grid'5000"
  s.description       = "Openstackg5k is a tool for deploy OpenStack cloud middleware on Grid'5000 using Puppet"
  s.author            = "Sebastien Badia"
  s.email             = "seb@sebian.fr"
  s.homepage          = "https://github.com/sbadia/openstack-campaign"

  s.add_dependency "mixlib-cli", ">= 1.1.0"
  s.add_dependency "restfully", ">= 0.8.6"
  s.add_dependency "net-scp", ">= 1.0.4"
  s.add_dependency "net-ssh-multi", ">= 1.1"
  s.add_dependency "rake", "0.8.7"

  s.bindir          = "bin"
  s.executables     = %w( openstackg5k )
  s.require_path      = ["lib"]
  s.files           = %w( README.md ) + Dir.glob("lib/*")
end

Rake::GemPackageTask.new(gemspec) do |pkg|
  pkg.gem_spec = gemspec
end

desc "Generate a gemspec file"
task :gemspec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts gemspec.to_ruby
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('GEM_VERSION') ? File.read('GEM_VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{GEM} #{GEM_VERSION}"
  rdoc.rdoc_files.include('README*')
end

namespace :repo do
  desc "Upload to Nancy"
  task :up do
    sh "ssh nancy.user 'rm -rf openstack-campaign'"
    sh "scp -r ~/dev/edge/openstack-campaign/ nancy.user:"
  end

  desc "Clean tmp files"
  task :clean do
    sh "rm -rf modules/puppet/files/master/{autosign.conf,install.pp,openstack.pp}"
    sh "rm -rf nodes"
  end
end

namespace :version do
  desc "New #{GEM} GIT release (v#{GEM_VERSION})"
  task :release do
    sh "git tag #{GEM_VERSION} -m \"New release: #{GEM_VERSION}\""
    sh "git push --tag"
  end

  namespace :bump do
    desc "Bump #{GEM} by a major version"
    task :major do
      bump_version(:major)
    end

    desc "Bump #{GEM} by a minor version"
    task :minor do
      bump_version(:minor)
    end

    desc "Bump #{GEM} by a patch version"
    task :patch do
      bump_version(:patch)
    end
  end
end

namespace :modules do
  desc 'clone all required modules'
  task :clone do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), 'repo.yml'))
    repos = (repo_hash['repos'] || {})
    repos_to_clone = (repos['repo_paths'] || {})
    repos_to_clone.each do |remote, local|
      outpath = File.join('./modules', local)
      `git clone #{remote} #{outpath}`
    end
  end
  desc 'clean all puppetlabs modules'
  task :clean do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), 'repo.yml'))
    repos = (repo_hash['repos'] || {})
    repos_to_clone = (repos['repo_paths'] || {})
    repos_to_clone.each do |remote, local|
      outpath = File.join('./modules', local)
      `rm -rf #{outpath}`
    end
  end
  desc 'update submodules'
  task :subup do
    `git submodule foreach git pull origin master`
  end
end

def bump_version(level)
  version_txt = GEM_VERSION
  if version_txt =~ /(\d+)\.(\d+)\.(\d+)/
    major = $1.to_i
    minor = $2.to_i
    patch = $3.to_i
  end

  case level
  when :major
    major += 1
    minor = 0
    patch = 0
  when :minor
    minor += 1
    patch = 0
  when :patch
    patch += 1
  end

  new_version = [major,minor,patch].compact.join('.')
  v = File.read(File.join(TDIR,'lib/openstackg5k.rb')).chomp
  v.gsub!(/(\d+)\.(\d+)\.(\d+)/,"#{new_version}")
  File.open(File.join(TDIR,'lib/openstackg5k.rb'), 'w') do |file|
    file.puts v
  end
end # def:: bump_version(level)
