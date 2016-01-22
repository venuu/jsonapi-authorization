source 'https://rubygems.org'

gemspec

gem 'sqlite3', '1.3.10'

version = ENV['RAILS_VERSION'] || 'default'

case version
when 'master'
  gem 'rails', git: 'https://github.com/rails/rails.git'
  gem 'arel', git: 'https://github.com/rails/arel.git'
when 'default'
  gem 'rails', '>= 4.2'
else
  gem 'rails', "~> #{version}"
end
