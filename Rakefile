# Author:: Sebastien Badia (<seb@sebian.fr>)
# Date:: Mon Jun 04 23:11:30 +0200 2012
require 'rubygems'
require 'yaml'
require 'lib/openstackg5k'

GEM = 'openstackg5k'
GEM_VERSION = Openstackg5k::VERSION
TDIR = File.expand_path(File.dirname(__FILE__))

namespace :repo do
  desc "Upload to Nancy"
  task :up do
    sh "ssh nancy.user 'rm -rf openstack-campaign'"
    sh "scp -r ~/dev/edge/openstack-campaign/ nancy.user:"
  end

  desc "Clean tmp files"
  task :clean do
    sh "rm -rf modules/puppet/files/master/{autosign.conf,site.pp}"
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
