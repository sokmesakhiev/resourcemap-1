source 'https://rubygems.org'

gem 'rails', '~> 3.2.0'
gem 'mysql2'
gem 'devise'
gem 'haml-rails', '~> 0.4'
gem 'gettext', '~> 3.1.2'
gem 'gettext_i18n_rails_js'
gem 'ruby_parser', :require => false, :group => :development
gem 'haml-magic-translations'
gem 'decent_exposure'
gem "instedd-rails", '~> 0.0.24'
gem "breadcrumbs_on_rails"
gem "elasticsearch"
gem "elasticsearch-ruby"
gem "valium"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', :require => 'resque_scheduler'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'newrelic_rpm'
gem 'cancan', '~> 1.6.10'
gem "omniauth"
gem "omniauth-openid"
gem 'alto_guisso', git: "https://bitbucket.org/instedd/alto_guisso.git", branch: 'master'
gem 'oj'
gem 'nokogiri'
gem 'carrierwave'
gem 'mini_magick'
gem 'activerecord-import'
gem 'active_model_serializers'
gem 'includes-count'
gem 'poirot_rails', git: "https://bitbucket.org/instedd/poirot_rails.git", branch: 'master' unless ENV['CI']

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter'
  gem 'resque_spec'
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'brakeman'
  gem 'timecop'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano'
  gem 'rvm'
  gem 'rvm-capistrano', '1.2.2'
  gem 'jasminerice'
  gem 'guard-jasmine'
  gem 'pry'
end

group :development do
  gem 'pry-stack_explorer'
  gem 'dist', :git => 'https://github.com/manastech/dist.git'
  gem 'ruby-prof', :git => 'https://github.com/ruby-prof/ruby-prof.git'
  gem 'pry-debugger'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  gem 'uglifier', '>= 1.0.3'
  gem 'lodash-rails'
end

