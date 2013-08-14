# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{redis-locker}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Sergei Zinin"]
  s.date = %q{2013-08-13}
  s.description = %q{A locking mechanism. Builds queue of concurrent code blocks using Redis.}
  s.email = %q{szinin@partyearth.com}
  s.extra_rdoc_files = [ "README.md" ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/einzige/redis-locker}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Destroys the concurrency of your code.}

  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
    s.add_runtime_dependency(%q<activesupport>, [">= 3.2.10"])
    s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_runtime_dependency(%q<logger>, [">= 1.2.8"])
    s.add_runtime_dependency(%q<redis>, [">= 3.0.3"])
  else
    s.add_dependency(%q<activesupport>, [">= 3.2.10"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<logger>, [">= 1.2.8"])
    s.add_dependency(%q<redis>, [">= 3.0.3"])
  end
end
