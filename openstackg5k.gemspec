# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "openstackg5k"
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sebastien Badia"]
  s.date = "2012-11-27"
  s.description = "Openstackg5k is a tool for deploy OpenStack cloud middleware on Grid'5000 using Puppet"
  s.email = "seb@sebian.fr"
  s.executables = ["openstackg5k"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md", "lib/openstackg5k.rb", "lib/puppetg5k.rb", "bin/openstackg5k"]
  s.homepage = "https://github.com/sbadia/openstack-campaign"
  s.require_paths = [["lib"]]
  s.rubygems_version = "1.8.23"
  s.summary = "A tool for deploy openstack on Grid'5000"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mixlib-cli>, [">= 1.1.0"])
      s.add_runtime_dependency(%q<restfully>, [">= 0.8.6"])
      s.add_runtime_dependency(%q<net-scp>, [">= 1.0.4"])
      s.add_runtime_dependency(%q<net-ssh-multi>, [">= 1.1"])
      s.add_runtime_dependency(%q<rake>, ["= 0.8.7"])
    else
      s.add_dependency(%q<mixlib-cli>, [">= 1.1.0"])
      s.add_dependency(%q<restfully>, [">= 0.8.6"])
      s.add_dependency(%q<net-scp>, [">= 1.0.4"])
      s.add_dependency(%q<net-ssh-multi>, [">= 1.1"])
      s.add_dependency(%q<rake>, ["= 0.8.7"])
    end
  else
    s.add_dependency(%q<mixlib-cli>, [">= 1.1.0"])
    s.add_dependency(%q<restfully>, [">= 0.8.6"])
    s.add_dependency(%q<net-scp>, [">= 1.0.4"])
    s.add_dependency(%q<net-ssh-multi>, [">= 1.1"])
    s.add_dependency(%q<rake>, ["= 0.8.7"])
  end
end
