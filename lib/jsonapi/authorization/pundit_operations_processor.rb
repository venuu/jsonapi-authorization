require 'pundit'

module JSONAPI
  module Authorization
    class PunditOperationsProcessor < ::ActiveRecordOperationsProcessor
      # set_callback :operation, :before, :log
      [
        :find_operation,
        :create_resource_operation,
        :replace_fields_operation
      ].each do |operation|
        set_callback operation, :before, :authorize
      end

      def authorize
        query = "#{action}?"
        ::Pundit.authorize(pundit_user, pundit_record, query)

        related_models.each do |rel_model|
          ::Pundit.authorize(pundit_user, rel_model, 'update?')
        end
      end

      # def log
      #   STDERR.puts "---------------------"
      #   STDERR.puts @operation.class.inspect
      #   STDERR.puts @operation.resource_klass
      #   STDERR.puts action
      #   STDERR.puts @operation.options.inspect
      #   STDERR.puts
      #   STDERR.puts pundit_record.inspect
      #   STDERR.puts
      #   STDERR.puts related_models.inspect
      # rescue => e
      #   STDERR.puts "Logging failed!"
      #   STDERR.puts e.inspect
      # ensure
      #   STDERR.puts
      #   STDERR.puts "---------------------"
      # end

      private

      def action
        @operation.options[:context][:action]
      end

      def pundit_user
        @operation.options[:context][:user]
      end

      def pundit_record
        if action.in?(%w(index create))
          @operation.resource_klass._model_class
        else
          @operation.resource_klass.find_by_key(
            @operation.resource_id,
            context: @operation.options[:context]
          )._model
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
