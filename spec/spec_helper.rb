$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../dummy/db/migrate", __FILE__)]

require "pry"
require "rspec/rails"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.use_transactional_fixtures = true
end
