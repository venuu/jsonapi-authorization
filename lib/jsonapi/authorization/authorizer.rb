module JSONAPI
  module Authorization
    class Authorizer
      attr_reader :user

      def initialize(context)
        @user = context[:user]
      end

      def find(source_record)
        ::Pundit.authorize(user, source_record, 'index?')
      end

      def show(source_record)
        ::Pundit.authorize(user, source_record, 'show?')
      end

      def show_relationship(source_record, related_record)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      def show_related_resource(source_record, related_record)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      def show_related_resources(source_record)
        ::Pundit.authorize(user, source_record, 'show?')
      end

      # TODO: Should probably take old records as well
      def replace_fields(source_record, new_related_records)
        ::Pundit.authorize(user, source_record, 'update?')

        new_related_records.each do |record|
          ::Pundit.authorize(user, record, 'update?')
        end
      end

      def create_resource(source_class, related_records)
        ::Pundit.authorize(user, source_class, 'create?')

        related_records.each do |record|
          ::Pundit.authorize(user, record, 'update?')
        end
      end

      def remove_resource(source_record)
        ::Pundit.authorize(user, source_record, 'destroy?')
      end

      def replace_to_one_relationship(source_record, old_related_record, new_related_record)
        raise NotImplementedError
      end

      def create_to_many_relationship(source_record, new_related_records)
        raise NotImplementedError
      end

      # TODO: Should probably take old records as well
      def replace_to_many_relationship(source_record, new_related_records)
        raise NotImplementedError
      end

      # Note: this is called once per related record, not all at once
      def remove_to_many_relationship(source_record, related_record)
        raise NotImplementedError
      end

      def remove_to_one_relationship(source_record, related_record)
        raise NotImplementedError
      end
    end
  end
end
