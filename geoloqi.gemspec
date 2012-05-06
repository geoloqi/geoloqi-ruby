require './lib/geoloqi/version.rb'
Gem::Specification.new do |s|
  s.name = 'geoloqi'
  s.version = Geoloqi.version
  s.authors = ['Kyle Drake', 'Aaron Parecki']
  s.email = ['kyle@geoloqi.com', 'aaron@geoloqi.com']
  s.homepage = 'http://github.com/geoloqi/geoloqi-ruby'
  s.summary = 'Powerful, flexible, lightweight interface to the Geoloqi Platform API'
  s.description = 'Powerful, flexible, lightweight, thread-safe interface to the Geoloqi Platform API'

  s.files = `git ls-files`.split("\n")
  s.require_paths = %w[lib]
  s.rubyforge_project = s.name
  s.required_rubygems_version = '>= 1.3.4'

  s.add_dependency 'json'
  s.add_dependency 'faraday',          '>= 0.6.1'
  s.add_development_dependency 'rack', '>= 0'

  s.add_development_dependency 'rake',     '>= 0'
  s.add_development_dependency 'minitest', '= 2.2.2'
  s.add_development_dependency 'webmock', '= 1.6.4'
  s.add_development_dependency 'hashie',  '= 1.0.0'
  s.add_development_dependency 'yard'
end