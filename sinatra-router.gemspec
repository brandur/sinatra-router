# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name        = 'sinatra-router'
  gem.version     = '0.2.4'

  gem.author      = 'Brandur'
  gem.email       = 'brandur@mutelight.org'
  gem.homepage    = 'https://github.com/brandur/sinatra-router'
  gem.license     = 'MIT'
  gem.summary     = 'A tiny vendorable router that makes it easy to try ' \
                    'routes from a number of different modular Sinatra applications.'

  gem.files = ['lib/sinatra/router.rb']

  gem.add_dependency 'sinatra', '>= 1.4', '< 3.0'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'rake'
end
