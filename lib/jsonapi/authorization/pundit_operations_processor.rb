require 'pundit'

module JSONAPI
  module Authorization
    class PunditOperationsProcessor < ::ActiveRecordOperationsProcessor
      set_callback :find_operation, :before, :authorize_find
      set_callback :show_operation, :before, :authorize_show
      set_callback :show_related_resource_operation, :before, :authorize_show_related_resource
      set_callback :show_related_resources_operation, :before, :authorize_show_related_resources
      set_callback :create_resource_operation, :before, :authorize_create_resource
      set_callback :replace_fields_operation, :before, :authorize_replace_fields

      def authorize_find
        ::Pundit.authorize(pundit_user, @operation.resource_klass._model_class, 'index?')
      end

      def authorize_show
        record = @operation.resource_klass.find_by_key(
          operation_resource_id,
          context: operation_context
        )._model

        ::Pundit.authorize(pundit_user, record, 'show?')
      end

      def authorize_show_related_resource
        source_resource = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )
        source_record = source_resource._model
        ::Pundit.authorize(pundit_user, source_record, 'show?')

        related_resource = source_resource.public_send(@operation.relationship_type)
        if related_resource.present?
          related_record = related_resource._model
          ::Pundit.authorize(pundit_user, related_record, 'show?')
        end
      end

      def authorize_show_related_resources
        source_record = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )._model

        ::Pundit.authorize(pundit_user, source_record, 'show?')
      end

      def authorize_replace_fields
        source_record = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )._model

        ::Pundit.authorize(pundit_user, source_record, 'update?')

        related_models.each do |rel_model|
          ::Pundit.authorize(pundit_user, rel_model, 'update?')
        end
      end

      def authorize_create_resource
        ::Pundit.authorize(pundit_user, @operation.resource_klass._model_class, 'create?')

        related_models.each do |rel_model|
          ::Pundit.authorize(pundit_user, rel_model, 'update?')
        end
      end

      private

      def pundit_user
        operation_context[:user]
      end

      # TODO: Communicate with upstream to fix this nasty hack
      def operation_context
        case @operation
        when JSONAPI::ShowRelatedResourcesOperation
          @operation.instance_variable_get('@options')[:context]
        else
          @operation.options[:context]
        end
      end

      # TODO: Communicate with upstream to fix this nasty hack
      def operation_resource_id
        case @operation
        when JSONAPI::ShowOperation
          @operation.id
        when JSONAPI::ShowRelatedResourcesOperation
          @operation.source_id
        else
          @operation.resource_id
        end
      end

      def model_class_for_relationship(assoc_name)
        @operation.resource_klass._relationships[assoc_name].resource_klass._model_class
      end

      def related_models
        data = @operation.options[:data]
        return [] if data.nil?

        [:to_one, :to_many].flat_map do |rel_type|
          data[rel_type].flat_map do |assoc_name, assoc_ids|
            assoc_klass = model_class_for_relationship(assoc_name)
            assoc_klass.find(assoc_ids)
          end
        end
      end
    end
  end
end
