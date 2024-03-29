# frozen_string_literal: true

module JSONAPI
  module Authorization
    # An authorizer is a class responsible for linking JSONAPI operations to
    # your choice of authorization mechanism.
    #
    # This class uses Pundit for authorization. You can use your own authorizer
    # class instead if you have different needs. See the README.md for
    # configuration information.
    #
    # Fetching records is the concern of +PunditScopedResource+ which in turn
    # affects which records end up being passed here.
    class DefaultPunditAuthorizer
      attr_reader :user

      # Creates a new DefaultPunditAuthorizer instance
      #
      # ==== Parameters
      #
      # * +context+ - The context passed down from the controller layer
      def initialize(context:)
        @user = JSONAPI::Authorization.configuration.user_context(context)
      end

      # <tt>GET /resources</tt>
      #
      # ==== Parameters
      #
      # * +source_class+ - The source class (e.g. +Article+ for +ArticleResource+)
      def find(source_class:)
        ::Pundit.authorize(user, source_class, 'index?')
      end

      # <tt>GET /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to show
      def show(source_record:)
        ::Pundit.authorize(user, source_record, 'show?')
      end

      # <tt>GET /resources/:id/relationships/other-resources</tt>
      # <tt>GET /resources/:id/relationships/another-resource</tt>
      #
      # A query for a +has_one+ or a +has_many+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is queried
      # * +related_record+ - The associated +has_one+ record to show or +nil+
      #   if the associated record was not found. For a +has_many+ association,
      #   this will always be +nil+
      def show_relationship(source_record:, related_record:)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      # <tt>GET /resources/:id/another-resource</tt>
      #
      # A query for a record through a +has_one+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is queried
      # * +related_record+ - The associated record to show or +nil+ if the
      #   associated record was not found
      def show_related_resource(source_record:, related_record:)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record, 'show?') unless related_record.nil?
      end

      # <tt>GET /resources/:id/other-resources</tt>
      #
      # A query for records through a +has_many+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is queried
      # * +related_record_class+ - The associated record class to show
      def show_related_resources(source_record:, related_record_class:)
        ::Pundit.authorize(user, source_record, 'show?')
        ::Pundit.authorize(user, related_record_class, 'index?')
      end

      # <tt>PATCH /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to be modified
      # * +related_records_with_context+ - A hash with the association type,
      # the relationship name, an Array of new related records.
      def replace_fields(source_record:, related_records_with_context:)
        ::Pundit.authorize(user, source_record, 'update?')
        authorize_related_records(
          source_record: source_record,
          related_records_with_context: related_records_with_context
        )
      end

      # <tt>POST /resources</tt>
      #
      # ==== Parameters
      #
      # * +source_class+ - The class of the record to be created
      # * +related_records_with_context+ - A has with the association type,
      # the relationship name, and an Array of new related records.
      def create_resource(source_class:, related_records_with_context:)
        ::Pundit.authorize(user, source_class, 'create?')
        related_records_with_context.each do |data|
          relation_name = data[:relation_name]
          records = data[:records]
          relationship_method = "create_with_#{relation_name}?"
          policy = ::Pundit.policy(user, source_class)
          if policy.respond_to?(relationship_method)
            unless policy.public_send(relationship_method, records)
              raise ::Pundit::NotAuthorizedError,
                    query: relationship_method,
                    record: source_class,
                    policy: policy
            end
          else
            Array(records).each do |record|
              ::Pundit.authorize(user, record, 'update?')
            end
          end
        end
      end

      # <tt>DELETE /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to be removed
      def remove_resource(source_record:)
        ::Pundit.authorize(user, source_record, 'destroy?')
      end

      # <tt>PATCH /resources/:id/relationships/another-resource</tt>
      #
      # A replace request for a +has_one+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +new_related_record+ - The new record replacing the old record
      # * +relationship_type+ - The relationship type
      def replace_to_one_relationship(source_record:, new_related_record:, relationship_type:)
        relationship_method = "replace_#{relationship_type}?"
        authorize_relationship_operation(
          source_record: source_record,
          relationship_method: relationship_method,
          related_record_or_records: new_related_record
        )
      end

      # <tt>POST /resources/:id/relationships/other-resources</tt>
      #
      # A request for adding to a +has_many+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +new_related_records+ - The new records to be added to the association
      # * +relationship_type+ - The relationship type
      def create_to_many_relationship(source_record:, new_related_records:, relationship_type:)
        relationship_method = "add_to_#{relationship_type}?"
        authorize_relationship_operation(
          source_record: source_record,
          relationship_method: relationship_method,
          related_record_or_records: new_related_records
        )
      end

      # <tt>PATCH /resources/:id/relationships/other-resources</tt>
      #
      # A replace request for a +has_many+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +new_related_records+ - The new records replacing the entire +has_many+
      #   association
      # * +relationship_type+ - The relationship type
      def replace_to_many_relationship(source_record:, new_related_records:, relationship_type:)
        relationship_method = "replace_#{relationship_type}?"
        authorize_relationship_operation(
          source_record: source_record,
          relationship_method: relationship_method,
          related_record_or_records: new_related_records
        )
      end

      # <tt>DELETE /resources/:id/relationships/other-resources</tt>
      #
      # A request to disassociate elements of a +has_many+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +related_records+ - The records which will be disassociated from +source_record+
      # * +relationship_type+ - The relationship type
      def remove_to_many_relationship(source_record:, related_records:, relationship_type:)
        relationship_method = "remove_from_#{relationship_type}?"
        authorize_relationship_operation(
          source_record: source_record,
          relationship_method: relationship_method,
          related_record_or_records: related_records
        )
      end

      # <tt>DELETE /resources/:id/relationships/another-resource</tt>
      #
      # A request to disassociate a +has_one+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +relationship_type+ - The relationship type
      def remove_to_one_relationship(source_record:, relationship_type:)
        relationship_method = "remove_#{relationship_type}?"
        authorize_relationship_operation(
          source_record: source_record,
          relationship_method: relationship_method
        )
      end

      # Any request including <tt>?include=other-resources</tt>
      #
      # This will be called for each has_many relationship if the include goes
      # deeper than one level until some authorization fails or the include
      # directive has been travelled completely.
      #
      # We can't pass all the records of a +has_many+ association here due to
      # performance reasons, so the class is passed instead.
      #
      # ==== Parameters
      #
      # * +source_record+ — The source relationship record, e.g. an Article in
      #                     article.comments check
      # * +record_class+ - The underlying record class for the relationships
      #                    resource.
      # rubocop:disable Lint/UnusedMethodArgument
      def include_has_many_resource(source_record:, record_class:)
        ::Pundit.authorize(user, record_class, 'index?')
      end
      # rubocop:enable Lint/UnusedMethodArgument

      # Any request including <tt>?include=another-resource</tt>
      #
      # This will be called for each has_one relationship if the include goes
      # deeper than one level until some authorization fails or the include
      # directive has been travelled completely.
      #
      # ==== Parameters
      #
      # * +source_record+ — The source relationship record, e.g. an Article in
      #                     article.author check
      # * +related_record+ - The associated record to return
      # rubocop:disable Lint/UnusedMethodArgument
      def include_has_one_resource(source_record:, related_record:)
        ::Pundit.authorize(user, related_record, 'show?')
      end
      # rubocop:enable Lint/UnusedMethodArgument

      private

      def authorize_relationship_operation(
        source_record:,
        relationship_method:,
        related_record_or_records: nil
      )
        policy = ::Pundit.policy(user, source_record)
        if policy.respond_to?(relationship_method)
          args = [relationship_method, related_record_or_records].compact
          unless policy.public_send(*args)
            raise ::Pundit::NotAuthorizedError,
                  query: relationship_method,
                  record: source_record,
                  policy: policy
          end
        else
          ::Pundit.authorize(user, source_record, 'update?')
          if related_record_or_records
            Array(related_record_or_records).each do |related_record|
              ::Pundit.authorize(user, related_record, 'update?')
            end
          end
        end
      end

      def authorize_related_records(source_record:, related_records_with_context:)
        related_records_with_context.each do |data|
          relation_type = data[:relation_type]
          relation_name = data[:relation_name]
          records = data[:records]
          case relation_type
          when :to_many
            replace_to_many_relationship(
              source_record: source_record,
              new_related_records: records,
              relationship_type: relation_name
            )
          when :to_one
            if records.nil?
              remove_to_one_relationship(
                source_record: source_record,
                relationship_type: relation_name
              )
            else
              replace_to_one_relationship(
                source_record: source_record,
                new_related_record: records,
                relationship_type: relation_name
              )
            end
          end
        end
      end
    end
  end
end
