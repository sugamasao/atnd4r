# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{atnd4r}
  s.version = "0.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["sugamasao"]
  s.date = %q{2009-07-28}
  s.email = %q{sugamasao@gmail.com}
  s.extra_rdoc_files = [
    "ChangeLog",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "ChangeLog",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "atnd4r.gemspec",
     "lib/atnd4r.rb",
     "spec/atnd4r_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/sugamasao/atnd4r}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{ATND の API を Ruby から使用するたのラッパークラスです}
  s.test_files = [
    "spec/atnd4r_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
