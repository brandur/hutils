Gem::Specification.new do |gem|
  gem.name        = "hutils"
  gem.version     = "0.2.2"

  gem.author      = "Brandur"
  gem.email       = "brandur@mutelight.org"
  gem.homepage    = "https://github.com/brandur/hutils"
  gem.license     = "MIT"
  gem.summary     = "A collection of command line utilities for working with logfmt."

  gem.executables = %w(lcut lfmt ltap lviz)
  gem.files = ["README.md"] + Dir["./lib/**/*.rb"]

  gem.add_dependency "excon", "~> 0.39", ">= 0.39.5"
  gem.add_dependency "inifile", "~> 3.0", ">= 3.0.0"
  gem.add_dependency "term-ansicolor", "~> 1.3", ">= 1.3.0"
end
