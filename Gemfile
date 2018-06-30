source 'https://rubygems.org'

gemspec

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
when 'default'
  gem 'jsonapi-resources', '0.9'
else
  gem 'jsonapi-resources', jsonapi_resources_version
end
