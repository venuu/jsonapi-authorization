source 'https://rubygems.org'

gemspec

gem 'sqlite3', '1.3.10'

rails_version = ENV['RAILS_VERSION'] || 'default'
jsonapi_resources_version = ENV['JSONAPI_RESOURCES_VERSION'] || 'default'

case rails_version
when 'master'
  gem 'rails', git: 'https://github.com/rails/rails.git'
  gem 'arel', git: 'https://github.com/rails/arel.git'
when 'default'
  gem 'rails', '>= 4.2'
else
  gem 'rails', "~> #{rails_version}"
end

case jsonapi_resources_version
when 'master'
  gem 'jsonapi-resources', git: 'https://github.com/cerebris/jsonapi-resources.git'
when 'default'
  gem 'jsonapi-resources', '0.7.0'
else
  gem 'jsonapi-resources', jsonapi_resources_version
end
