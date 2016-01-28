require 'jsonapi/authorization/authorizer'

module JSONAPI
  module Authorization
    class Configuration
      attr_accessor :authorizer

      def initialize
        self.authorizer = ::JSONAPI::Authorization::Authorizer
      end
    end

    class << self
      attr_accessor :configuration
    end

    @configuration ||= Configuration.new

    def self.configure
      yield(@configuration)
    end
  end
end
