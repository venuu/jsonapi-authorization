module JSONAPI
  module Authorization
    class Authorizer
      attr_reader :user

      def initialize(context)
        @user = context[:user]
      end

      def find(record)
        ::Pundit.authorize(user, record, 'index?')
      end

      def show(record)
        ::Pundit.authorize(user, record, 'show?')
      end

      def show_relationship(source_record, related_record)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      def show_related_resource(source_record, related_record)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      def show_related_resources(record)
        ::Pundit.authorize(user, record, 'show?')
      end

      def replace_fields(source_record, related_records)
        ::Pundit.authorize(user, source_record, 'update?')

        related_records.each do |record|
          ::Pundit.authorize(user, record, 'update?')
        end
      end

      def create_resource(source_class, related_records)
        ::Pundit.authorize(user, source_class, 'create?')

        related_records.each do |record|
          ::Pundit.authorize(user, record, 'update?')
        end
      end

      def remove_resource(record)
        ::Pundit.authorize(user, record, 'destroy?')
      end
    end
  end
end
