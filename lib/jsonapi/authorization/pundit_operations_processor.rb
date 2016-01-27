require 'pundit'

module JSONAPI
  module Authorization
    class PunditOperationsProcessor < ::ActiveRecordOperationsProcessor
      set_callback :find_operation, :before, :authorize_find
      set_callback :show_operation, :before, :authorize_show
      set_callback :show_relationship_operation, :before, :authorize_show_relationship
      set_callback :show_related_resource_operation, :before, :authorize_show_related_resource
      set_callback :show_related_resources_operation, :before, :authorize_show_related_resources
      set_callback :create_resource_operation, :before, :authorize_create_resource
      set_callback :remove_resource_operation, :before, :authorize_remove_resource
      set_callback :replace_fields_operation, :before, :authorize_replace_fields

      def authorize_find
        authorizer.index(@operation.resource_klass._model_class)
      end

      def authorize_show
        record = @operation.resource_klass.find_by_key(
          operation_resource_id,
          context: operation_context
        )._model

        authorizer.show(record)
      end

      def authorize_show_relationship
        parent_resource = @operation.resource_klass.find_by_key(
          @operation.parent_key,
          context: operation_context
        )
        parent_record = parent_resource._model
        authorizer.show(parent_record)

        relationship = @operation.resource_klass._relationship(@operation.relationship_type)

        case relationship
        when JSONAPI::Relationship::ToOne
          related_resource = parent_resource.public_send(@operation.relationship_type)
          if related_resource.present?
            related_record = related_resource._model
            authorizer.show(related_record)
          end
        when JSONAPI::Relationship::ToMany
          # Do nothing — already covered by policy scopes
        else
          raise "Unexpected relationship type: #{relationship.inspect}"
        end
      end

      def authorize_show_related_resource
        source_resource = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )
        source_record = source_resource._model
        authorizer.show(source_record)

        related_resource = source_resource.public_send(@operation.relationship_type)
        if related_resource.present?
          related_record = related_resource._model
          authorizer.show(related_record)
        end
      end

      def authorize_show_related_resources
        source_record = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )._model

        authorizer.show(source_record)
      end

      def authorize_replace_fields
        source_record = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )._model

        authorizer.update(source_record)

        related_models.each do |rel_model|
          authorizer.update(rel_model)
        end
      end

      def authorize_create_resource
        authorizer.create(@operation.resource_klass._model_class)

        related_models.each do |rel_model|
          authorizer.update(rel_model)
        end
      end

      def authorize_remove_resource
        record = @operation.resource_klass.find_by_key(
          operation_resource_id,
          context: operation_context
        )._model

        authorizer.destroy(record)
      end

      private

      def authorizer
        @authorizer ||= Authorizer.new(operation_context)
      end

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
        @operation.resource_klass._relationship(assoc_name).resource_klass._model_class
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
