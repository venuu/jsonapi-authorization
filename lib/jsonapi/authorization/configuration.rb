# frozen_string_literal: true

require 'jsonapi/authorization/default_pundit_authorizer'

module JSONAPI
  module Authorization
    class Configuration
      attr_accessor :authorizer, :pundit_user

      def initialize
        self.authorizer  = ::JSONAPI::Authorization::DefaultPunditAuthorizer
        self.pundit_user = :user
      end

      def user_context(context)
        if pundit_user.is_a?(Symbol)
          context[pundit_user]
        else
          pundit_user.call(context)
        end
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
