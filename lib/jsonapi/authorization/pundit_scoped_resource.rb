require 'pundit'

module JSONAPI
  module Authorization
    module PunditScopedResource
      extend ActiveSupport::Concern

      module ClassMethods
        def records(options = {})
          user_context = JSONAPI::Authorization.configuration.user_context(options[:context])
          ::Pundit.policy_scope!(user_context, _model_class)
        end
      end

      def records_for(association_name)
        record_or_records = @model.public_send(association_name)
        relationship = self.class._relationships[association_name]

        case relationship
        when JSONAPI::Relationship::ToOne
          record_or_records
        when JSONAPI::Relationship::ToMany
          user_context = JSONAPI::Authorization.configuration.user_context(context)
          ::Pundit.policy_scope!(user_context, record_or_records)
        else
          raise "Unknown relationship type #{relationship.inspect}"
        end
      end
    end
  end
end
