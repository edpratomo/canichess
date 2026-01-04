source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.8'

gem 'pg'
gem 'devise', github: 'heartcombo/devise'
gem 'gravtastic'
gem 'pundit'
gem 'textacular', '~> 5.0'
gem 'render_async'
#gem 'will_paginate'
gem 'will_paginate-bootstrap-style'
gem 'filterrific'
gem "schema_validations"
gem 'dotenv-rails'

group :development, :test do
  gem 'rspec-rails'
  gem 'shoulda-matchers', '~> 5.0'
  gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'master'
  gem 'factory_bot_rails'
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.5', '>= 6.1.4.4'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'capistrano', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma', require: false
  gem 'capistrano-nvm', require: false
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.40'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'swissper'
gem 'glicko2'
gem 'stimulus-rails'
gem 'activerecord-session_store'

gem 'net-smtp', require: false
gem 'net-pop', require: false
gem 'net-imap', require: false
gem 'base64', require: false
gem 'bigdecimal', require: false
gem 'mutex_m', require: false
gem 'puma-daemon', require: false

gem "rack", ">= 2.2.7"

gem "meta-tags", "~> 2.22"

gem "lucide-rails", "~> 0.7.1"

gem "view_component", "~> 3.24"

gem "gretel", "~> 5.1"

gem "turbo-rails", "~> 2.0"

gem "faraday", "~> 2.14"

gem "googleauth", "~> 1.16"
