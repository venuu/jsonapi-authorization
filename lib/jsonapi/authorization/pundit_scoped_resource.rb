require 'pundit'

module JSONAPI
  module Authorization
    module PunditScopedResource
      extend ActiveSupport::Concern

      module ClassMethods
        def records(options = {})
          user_context = JSONAPI::Authorization.configuration.user_context(options[:context])
          policy_path = build_policy_path(_model_class)
          ::Pundit.policy_scope!(user_context, policy_path)
        end

        def build_policy_path(model_class)
          nested_paths = name.underscore.split('/')[0...-1].map(&:to_sym)
          nested_paths.any? ? nested_paths << model_class : model_class
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
          policy_path = self.class.build_policy_path(record_or_records)
          ::Pundit.policy_scope!(user_context, policy_path)
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
