Gem::Specification.new do |s|
  s.name         = 'mobj'
  s.version      = '3.0.0'
  s.author       = 'Mason Glaves'
  s.email        = 'mobj@chipped.net'
  s.homepage     = 'https://github.com/gnovos/mobj'

  s.files        = Dir['lib/**/*.rb', '*.{md,rdoc,txt}']
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'awesome_print'

  s.summary      = 'Helpful utils and extentions'
  s.description  = <<-DESC
Utils and extentions for various ruby objects
  DESC

end
