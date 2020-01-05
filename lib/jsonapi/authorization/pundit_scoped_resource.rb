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

        def apply_joins(records, join_manager, options)
          records = super
          join_manager.join_details.each do |k, v|
            next if k == '' || v[:join_type] == :root
            v[:join_options][:relationship_details][:resource_klasses].each_key do |klass|
              next unless klass.included_modules.include?(PunditScopedResource)
              records = records.where(v[:alias] => { klass._primary_key => klass.records(options)})
            end
          end
          records
        end
      end
    end
  end
end
