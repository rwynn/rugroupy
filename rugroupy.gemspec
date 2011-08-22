# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rugroupy}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Ryan Wynn}]
  s.date = %q{2011-08-22}
  s.description = %q{a library which uses the map-reduce capabilities of mongodb to group entities based on tags.}
  s.email = %q{ryan.m.wynn@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "lib/rugroupy.rb",
    "lib/rugroupy/entity.rb",
    "lib/rugroupy/group.rb"
  ]
  s.homepage = %q{http://github.com/rwynn/rugroupy}
  s.licenses = [%q{MIT}]
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.6}
  s.summary = %q{find things that are similiar to things}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mongo>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<bson>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<bson_ext>, [">= 1.3.1"])
      s.add_runtime_dependency(%q<SystemTimer>, [">= 1.2.3"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
    else
      s.add_dependency(%q<mongo>, [">= 1.3.1"])
      s.add_dependency(%q<bson>, [">= 1.3.1"])
      s.add_dependency(%q<bson_ext>, [">= 1.3.1"])
      s.add_dependency(%q<SystemTimer>, [">= 1.2.3"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
    end
  else
    s.add_dependency(%q<mongo>, [">= 1.3.1"])
    s.add_dependency(%q<bson>, [">= 1.3.1"])
    s.add_dependency(%q<bson_ext>, [">= 1.3.1"])
    s.add_dependency(%q<SystemTimer>, [">= 1.2.3"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
  end
end

