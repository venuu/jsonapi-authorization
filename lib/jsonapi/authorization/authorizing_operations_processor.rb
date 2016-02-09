require 'pundit'

module JSONAPI
  module Authorization
    class AuthorizingOperationsProcessor < ::ActiveRecordOperationsProcessor
      set_callback :find_operation, :before, :authorize_find
      set_callback :show_operation, :before, :authorize_show
      set_callback :show_relationship_operation, :before, :authorize_show_relationship
      set_callback :show_related_resource_operation, :before, :authorize_show_related_resource
      set_callback :show_related_resources_operation, :before, :authorize_show_related_resources
      set_callback :create_resource_operation, :before, :authorize_create_resource
      set_callback :remove_resource_operation, :before, :authorize_remove_resource
      set_callback :replace_fields_operation, :before, :authorize_replace_fields
      set_callback :replace_to_one_relationship_operation, :before, :authorize_replace_to_one_relationship
      set_callback :create_to_many_relationship_operation, :before, :authorize_create_to_many_relationship
      set_callback :replace_to_many_relationship_operation, :before, :authorize_replace_to_many_relationship
      set_callback :remove_to_many_relationship_operation, :before, :authorize_remove_to_many_relationship
      set_callback :remove_to_one_relationship_operation, :before, :authorize_remove_to_one_relationship

      def authorize_find
        authorizer.find(@operation.resource_klass._model_class)
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

        relationship = @operation.resource_klass._relationship(@operation.relationship_type)

        related_resource =
          case relationship
          when JSONAPI::Relationship::ToOne
            parent_resource.public_send(@operation.relationship_type)
          when JSONAPI::Relationship::ToMany
            # Do nothing — already covered by policy scopes
          else
            raise "Unexpected relationship type: #{relationship.inspect}"
          end

        parent_record = parent_resource._model
        related_record = related_resource._model unless related_resource.nil?
        authorizer.show_relationship(parent_record, related_record)
      end

      def authorize_show_related_resource
        source_resource = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )

        related_resource = source_resource.public_send(@operation.relationship_type)

        source_record = source_resource._model
        related_record = related_resource._model unless related_resource.nil?
        authorizer.show_related_resource(source_record, related_record)
      end

      def authorize_show_related_resources
        source_record = @operation.source_klass.find_by_key(
          @operation.source_id,
          context: operation_context
        )._model

        authorizer.show_related_resources(source_record)
      end

      def authorize_replace_fields
        source_record = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )._model

        authorizer.replace_fields(source_record, related_models)
      end

      def authorize_create_resource
        source_class = @operation.resource_klass._model_class

        authorizer.create_resource(source_class, related_models)
      end

      def authorize_remove_resource
        record = @operation.resource_klass.find_by_key(
          operation_resource_id,
          context: operation_context
        )._model

        authorizer.remove_resource(record)
      end

      def authorize_replace_to_one_relationship
        source_resource = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )
        source_record = source_resource._model

        old_related_record = source_resource.records_for(@operation.relationship_type)
        unless @operation.key_value.nil?
          new_related_resource = @operation.resource_klass._relationship(@operation.relationship_type).resource_klass.find_by_key(
            @operation.key_value,
            context: operation_context
          )
          new_related_record = new_related_resource._model unless new_related_resource.nil?
        end

        authorizer.replace_to_one_relationship(
          source_record,
          old_related_record,
          new_related_record
        )
      end

      def authorize_create_to_many_relationship
        source_record = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )._model

        related_models =
          model_class_for_relationship(@operation.relationship_type).find(@operation.data)

        authorizer.create_to_many_relationship(source_record, related_models)
      end

      def authorize_replace_to_many_relationship
        source_resource = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )
        source_record = source_resource._model

        related_records = source_resource.records_for(@operation.relationship_type)

        authorizer.replace_to_many_relationship(
          source_record,
          related_records
        )
      end

      def authorize_remove_to_many_relationship
        source_resource = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )
        source_record = source_resource._model

        related_resource = @operation.resource_klass._relationship(@operation.relationship_type).resource_klass.find_by_key(
          @operation.associated_key,
          context: operation_context
        )
        related_record = related_resource._model unless related_resource.nil?

        authorizer.remove_to_many_relationship(
          source_record,
          related_record
        )
      end

      def authorize_remove_to_one_relationship
        source_resource = @operation.resource_klass.find_by_key(
          @operation.resource_id,
          context: operation_context
        )

        related_resource = source_resource.public_send(@operation.relationship_type)

        source_record = source_resource._model
        related_record = related_resource._model unless related_resource.nil?
        authorizer.remove_to_one_relationship(source_record, related_record)
      end

      private

      def authorizer
        @authorizer ||= ::JSONAPI::Authorization.configuration.authorizer.new(operation_context)
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

      def resource_class_for_relationship(assoc_name)
        @operation.resource_klass._relationship(assoc_name).resource_klass
      end

      def model_class_for_relationship(assoc_name)
        resource_class_for_relationship(assoc_name)._model_class
      end

      def related_models
        data = @operation.options[:data]
        return [] if data.nil?

        [:to_one, :to_many].flat_map do |rel_type|
          data[rel_type].flat_map do |assoc_name, assoc_ids|
            resource_class = resource_class_for_relationship(assoc_name)
            primary_key = resource_class._primary_key
            resource_class._model_class.where(primary_key => assoc_ids)
          end
        end
      end
    end
  end
end
