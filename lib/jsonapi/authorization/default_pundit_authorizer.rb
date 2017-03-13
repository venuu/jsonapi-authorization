module JSONAPI
  module Authorization
    # An authorizer is a class responsible for linking JSONAPI operations to
    # your choice of authorization mechanism.
    #
    # This class uses Pundit for authorization. It does not yet support all
    # the available operations — you can use your own authorizer class instead
    # if you have different needs. See the README.md for configuration
    # information.
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
      def initialize(context)
        @user = JSONAPI::Authorization.configuration.user_context(context)
      end

      # <tt>GET /resources</tt>
      #
      # ==== Parameters
      #
      # * +source_class+ - The source class (e.g. +Article+ for +ArticleResource+)
      def find(source_class)
        ::Pundit.authorize(user, source_class, 'index?')
      end

      # <tt>GET /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to show
      def show(source_record)
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
      def show_relationship(source_record, related_record)
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
      def show_related_resource(source_record, related_record)
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
      def show_related_resources(source_record)
        ::Pundit.authorize(user, source_record, 'show?')
      end

      # <tt>PATCH /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to be modified
      # * +related_records_with_context+ - A has with the relationship object,
      # the relationship name, an Array of new related records.
      def replace_fields(source_record, related_records_with_context)
        ::Pundit.authorize(user, source_record, 'update?')
        related_records_with_context.each do |data|
          relationship  = data[:relationship]
          relation_name = data[:relation_name]
          records = data[:records]

          # Authorize removing old records 
          case relationship
          when JSONAPI::Relationship::ToMany
            old_records = source_record.send relation_name
            authorize_relationship_operation(
              source_record, 
              relationship_method(data, prefix: 'remove'), 
              old_records
            )
          else
            authorize_relationship_operation(
              source_record,
              relationship_method(data, prefix: 'remove')
            )
          end

          # Authorize adding new records
          authorize_relationship_operation(source_record, relationship_method(data), records)
        end
      end

      # <tt>POST /resources</tt>
      #
      # ==== Parameters
      #
      # * +source_class+ - The class of the record to be created
      # * +related_records_with_context+ - A hash with the relationship, 
      # relation name, and records to be associated with the new record. This
      # will contain the records specified in the "relationships" key in the request
      def create_resource(source_class, related_records_with_context)
        ::Pundit.authorize(user, source_class, 'create?')
        related_records_with_context.each do |data|
          records = data[:records]
          add_method_name = relationship_method(data)
          authorize_relationship_operation(source_class, add_method_name, records)
        end
      end

      # <tt>DELETE /resources/:id</tt>
      #
      # ==== Parameters
      #
      # * +source_record+ - The record to be removed
      def remove_resource(source_record)
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
      def replace_to_one_relationship(source_record, new_related_record, relationship_type)
        relationship_method = "replace_#{relationship_type}?"
        authorize_relationship_operation(source_record, relationship_method, new_related_record)
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
      def create_to_many_relationship(source_record, new_related_records, relationship_type)
        relationship_method = "add_to_#{relationship_type}?"
        authorize_relationship_operation(source_record, relationship_method, new_related_records)
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
      def replace_to_many_relationship(source_record, new_related_records, relationship_type)
        relationship_method = "replace_#{relationship_type}?"
        authorize_relationship_operation(source_record, relationship_method, new_related_records)
      end

      # <tt>DELETE /resources/:id/relationships/other-resources</tt>
      #
      # A request to disassociate elements of a +has_many+ association
      #
      # NOTE: this is called once per related record, not all at once
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +related_record+ - The record which will be disassociated from +source_record+
      # * +relationship_type+ - The relationship type
      def remove_to_many_relationship(source_record, related_record, relationship_type)
        relationship_method = "remove_from_#{relationship_type}?"
        authorize_relationship_operation(source_record, relationship_method, related_record)
      end

      # <tt>DELETE /resources/:id/relationships/another-resource</tt>
      #
      # A request to disassociate a +has_one+ association
      #
      # ==== Parameters
      #
      # * +source_record+ - The record whose relationship is modified
      # * +relationship_type+ - The relationship type
      def remove_to_one_relationship(source_record, relationship_type)
        relationship_method = "remove_#{relationship_type}?"
        authorize_relationship_operation(source_record, relationship_method)
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
      def include_has_many_resource(_source_record, record_class)
        ::Pundit.authorize(user, record_class, 'index?')
      end

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
      def include_has_one_resource(_source_record, related_record)
        ::Pundit.authorize(user, related_record, 'show?')
      end

      private

      def authorize_relationship_operation(source_record, relationship_method, *args)
        policy = ::Pundit.policy(user, source_record)
        if policy.respond_to?(relationship_method)
          unless policy.public_send(relationship_method, *args)
            raise ::Pundit::NotAuthorizedError,
                  query: relationship_method,
                  record: source_record,
                  policy: policy
          end
        else
          ::Pundit.authorize(user, source_record, 'update?')
        end
      end

      def relationship_method(data, **options)
        relationship = data[:relationship]
        assoc_name   = data[:relation_name]
        prefix       = options[:prefix] || 'add'

        case relationship
        when ->(relationship) { relationship.polymorphic }
          polymorphic_type = data[:records].class.name.downcase
          "#{prefix}_#{relationship.class_name.downcase}_#{polymorphic_type}?"
        when JSONAPI::Relationship::ToOne
          "#{prefix}_#{assoc_name}?"
        else
          prefix_preposition = prefix == 'add' ? 'to' : 'from'
          "#{prefix}_#{prefix_preposition}_#{assoc_name}?"
        end
      end
    end
  end
end
