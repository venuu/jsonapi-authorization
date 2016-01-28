require 'jsonapi/authorization/default_pundit_authorizer'

module JSONAPI
  module Authorization
    class Configuration
      attr_accessor :authorizer

      def initialize
        self.authorizer = ::JSONAPI::Authorization::DefaultPunditAuthorizer
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
