$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb", __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../dummy/db/migrate", __FILE__)]

ActiveRecord::Migration.maintain_test_schema!

require "pry"
require "rspec/rails"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.fixture_path = File.expand_path("../fixtures", __FILE__)

  config.use_transactional_fixtures = true

  config.example_status_persistence_file_path =
    File.expand_path("../../tmp/rspec-example-statuses.txt", __FILE__)
end
