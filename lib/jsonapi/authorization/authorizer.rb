module JSONAPI
  module Authorization
    class Authorizer
      attr_reader :user

      def initialize(context)
        @user = context[:user]
      end

      def index(record)
        ::Pundit.authorize(user, record, 'index?')
      end

      def show(record)
        ::Pundit.authorize(user, record, 'show?')
      end

      def update(record)
        ::Pundit.authorize(user, record, 'update?')
      end

      def create(record)
        ::Pundit.authorize(user, record, 'create?')
      end

      def destroy(record)
        ::Pundit.authorize(user, record, 'destroy?')
      end
    end
  end
end
