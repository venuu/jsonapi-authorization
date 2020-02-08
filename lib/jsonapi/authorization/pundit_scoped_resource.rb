require 'pundit'

module JSONAPI
  module Authorization
    module PunditScopedResource
      extend ActiveSupport::Concern

      module ClassMethods
        def records(options = {})
          user_context = JSONAPI::Authorization.configuration.user_context(options[:context])
          ::Pundit.policy_scope!(user_context, super)
        end
      end
    end
  end
end
