require 'pundit'

module JSONAPI
  module Authorization
    module ResourcePolicyAuthorization
      extend ActiveSupport::Concern

      class_methods do
        def records(options = {})
          ::Pundit.policy_scope!(options[:context][:user], _model_class)
        end
      end

      included do
        [:save, :remove].each do |action|
          set_callback action, :before, :authorize
        end
      end

      def records_for(association_name)
        record_or_records = @model.public_send(association_name)
        relationship = self.class._relationships[association_name]

        case relationship
        when JSONAPI::Relationship::ToOne
          record = record_or_records
          authorize_record(record)
          record
        when JSONAPI::Relationship::ToMany
          records = ::Pundit.policy_scope!(context[:user], record_or_records)

          unless context[:action].in?(%w(index show))
            records.each(&authorize_record)
          end

          records
        else
          raise "Unknown relationship type #{relationship.inspect}"
        end
      end

      private

      def authorize
        authorize_record(@model)
      end

      def authorize_record(record)
        query = "#{context[:action]}?"
        ::Pundit.authorize(context[:user], record, query)
      end
    end
  end
end
