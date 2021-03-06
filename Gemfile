source 'http://rubygems.org'
source 'http://gems.github.com'

gem 'rails',        '~> 4.0.3'
gem 'jquery-rails', '~> 2.0.2'
gem 'haml',         '~> 4.0'
gem 'json',         '~> 1.8.1'

gem 'gravatar_image_tag'

# Ruby gems
gem 'ruby_deep_clone',        github: 'balmma/ruby-deepclone', require: 'deep_clone'
gem 'distribution', '~> 0.6'
gem 'text-table'
gem 'osmosis',                github: 'quintel/osmosis'

# Rails gem
gem 'simple_form'
gem 'devise'
gem 'cancan'
gem 'ruby-graphviz',                  require: 'graphviz'
gem 'rack-cors',                      require: 'rack/cors'
gem 'kaminari'

gem 'dotenv-rails', groups: [:development, :test, :production, :staging]

# API
gem 'rest-client'

# for etsource
gem 'git',                            github: 'bradhe/ruby-git'
gem 'fnv'
gem 'msgpack'

# own gems
gem 'rubel',         ref: 'd2ab773',   github:  'quintel/rubel'
gem 'merit',         '>=0.1.0',        github:  'quintel/merit'
gem 'turbine-graph', '>=0.1',          require: 'turbine'
gem 'refinery',      ref: 'f29ead1',   github:  'quintel/refinery'
gem 'atlas',         ref: '8828195',   github:  'quintel/atlas'

# system gems
gem 'mysql2',         '~>0.3.11'
gem 'dalli'

gem 'term-ansicolor', '1.0.7', require: false
gem 'highline',                require: false

group :development do
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'listen'

  gem 'capistrano',         require: false
  gem 'capistrano-unicorn', require: false
end

group :test, :development do
  gem 'rspec-rails', '~> 2.12'
  gem 'pry-rails'
  gem 'pry-remote'
  gem 'pry-stack_explorer'
  gem 'pry-debugger'
  gem 'guard'
  gem 'guard-rspec'
  gem 'watchr'
end

group :test do
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'simplecov', '~> 0.7.1', require: false
end

group :production, :staging do
  gem 'unicorn'
  gem 'gctools', require: false
  gem 'airbrake'
  gem 'newrelic_rpm'
end

group :assets do
  gem 'sass-rails'
  gem 'therubyracer', '>= 0.12.0'
  gem 'coffee-rails'
end
