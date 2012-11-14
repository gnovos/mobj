Gem::Specification.new do |s|
  s.name         = 'mobj'
  s.version      = '1.6.3'
  s.homepage     = 'https://github.com/gnovos/mobj'
  s.summary      = 'Helpful utils and extentions'
  s.description  = 'Utils and extentions for various ruby objects'
  s.authors      = %w(Mason)
  s.email        = 'mobj@chipped.net'
  s.files        = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.require_path = 'lib'
  s.bindir       = 'bin'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rr'
  s.add_development_dependency 'awesome_print'
end
