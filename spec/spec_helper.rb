# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path('dummy/config/environment.rb', __dir__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path('dummy/db/migrate', __dir__)]

ActiveRecord::Migration.maintain_test_schema!

require "pry"
require "rspec/rails"

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.fixture_path = File.expand_path('fixtures', __dir__)

  config.use_transactional_fixtures = true

  config.example_status_persistence_file_path =
    File.expand_path('../tmp/rspec-example-statuses.txt', __dir__)
end
