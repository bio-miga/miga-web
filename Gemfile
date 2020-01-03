source 'https://rubygems.org'

#Fang Yuan Add two gem dependencies
gem 'execjs' 
gem 'therubyracer'
# Use MiGA base code to communicate with the projects
gem 'miga-base', '~> 0.5'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2'
# Make it safe
gem 'bcrypt', '~> 3.1'
# Mock-up users
gem 'faker', '1.4.2'
# Paginaaaaaaaaaaation
gem 'will_paginate', '~> 3.1'
gem 'bootstrap-will_paginate', '0.0.10'
# Style-it-up!
gem 'bootstrap-sass', '>= 3.2'
# Upload files
gem 'carrierwave', '>= 0.10'
# Use sqlite3 as the database for Active Record
gem 'sqlite3', '~> 1.4.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '>= 4.1.0'
# The machinery behind code-colors :)
gem 'color', '>= 1.8'
gem 'xxhash', '>= 0.3'
# To spawn NCBI downloads
gem 'spawnling', '~> 2.1'
# To plot stuff
gem 'chartkick', '>= 3.2.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
# To contact RDP via SOAP (the REST client is heavier on RDP's servers)
gem 'savon', '~> 2.11'
# To easily configure local settings
gem 'config', '~> 1.2'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster.
# Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 1.0.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

gem 'redcarpet', '~> 3'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console
  # gem 'byebug'
  gem "simplecov"
  gem "codeclimate-test-reporter", "~> 1.0.0"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'

  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :production do
  #gem 'pg', '0.17.1'
  gem 'rails_12factor', '0.0.2'
  gem 'puma', '~> 3.12'
end

