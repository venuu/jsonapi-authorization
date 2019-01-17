require 'pundit'

module JSONAPI
  module Authorization
    module PunditScopedResource
      extend ActiveSupport::Concern

      module ClassMethods
        def records(options = {})
          user_context = JSONAPI::Authorization.configuration.user_context(options[:context])
          name_space = JSONAPI::Authorization.configuration.name_space(options[:context])
          ::Pundit.policy_scope!(user_context, name_space + [_model_class])
        end
      end

      def records_for(association_name)
        record_or_records = @model.public_send(association_name)
        relationship = fetch_relationship(association_name)

        case relationship
        when JSONAPI::Relationship::ToOne
          record_or_records
        when JSONAPI::Relationship::ToMany
          user_context = JSONAPI::Authorization.configuration.user_context(context)
          name_space = JSONAPI::Authorization.configuration.name_space(context)
          ::Pundit.policy_scope!(user_context, name_space + [record_or_records])
        else
          raise "Unknown relationship type #{relationship.inspect}"
        end
      end

      private

      def fetch_relationship(association_name)
        relationships = self.class._relationships.select do |_k, v|
          v.relation_name(context: context) == association_name
        end
        if relationships.empty?
          nil
        else
          relationships.values.first
        end
      end
    end
  end
end
