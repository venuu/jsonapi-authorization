require 'spec_helper'

RSpec.describe JSONAPI::Authorization::DefaultPunditAuthorizer do
  include PunditStubs
  fixtures :all

  let(:source_record) { Article.new }
  let(:namespace) { %i[api v1] }
  let(:ns_source) { namespace + [source_record] }
  let(:authorizer) { described_class.new(context: { namespace: namespace }) }

  shared_examples_for :update_singular_fallback do |related_record_method|
    context 'authorized for update? on related record' do
      before {
        stub_policy_actions(namespace + [send(related_record_method)], update?: true)
      }

      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for update? on related record' do
      before {
        stub_policy_actions(namespace + [send(related_record_method)], update?: false)
      }

      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  shared_examples_for :update_multiple_fallback do |related_records_method|
    context 'authorized for update? on all related records' do
      before do
        send(related_records_method)
          .each { |r| stub_policy_actions(namespace + [r], update?: true) }
      end

      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for update? on any related records' do
      before do
        stub_policy_actions(namespace + [send(related_records_method).first], update?: false)
      end

      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#find' do
    subject(:method_call) do
      -> { authorizer.find(source_class: source_record) }
    end

    context 'authorized for index? on record' do
      before { allow_action(ns_source, 'index?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for index? on record' do
      before { disallow_action(ns_source, 'index?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show' do
    subject(:method_call) do
      -> { authorizer.show(source_record: source_record) }
    end

    context 'authorized for show? on record' do
      before { allow_action(ns_source, 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(ns_source, 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show_relationship' do
    subject(:method_call) do
      lambda do
        authorizer.show_relationship(
          source_record: source_record, related_record: related_record
        )
      end
    end

    context 'authorized for show? on source record' do
      before { allow_action(ns_source, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(namespace + [related_record], 'show?') }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      before { disallow_action(ns_source, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#show_related_resource' do
    subject(:method_call) do
      lambda do
        authorizer.show_related_resource(
          source_record: source_record,
          related_record: related_record
        )
      end
    end

    context 'authorized for show? on source record' do
      before { allow_action(ns_source, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(namespace + [related_record], 'show?') }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      before { disallow_action(ns_source, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(namespace + [related_record], 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#show_related_resources' do
    subject(:method_call) do
      -> { authorizer.show_related_resources(source_record: source_record) }
    end

    context 'authorized for show? on record' do
      before { allow_action(ns_source, 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(ns_source, 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#replace_fields' do
    describe 'with "relation_type: :to_one"' do
      let(:related_record) { User.new }
      let(:related_records_with_context) do
        [{
          relation_name: :author,
          relation_type: :to_one,
          records: related_record
        }]
      end

      subject(:method_call) do
        lambda do
          authorizer.replace_fields(
            source_record: source_record,
            related_records_with_context: related_records_with_context
          )
        end
      end

      context 'authorized for replace_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_author?: true, update?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for replace_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_author?: false, update?: true) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for replace_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_author?: true, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for replace_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_author?: false, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'where replace_<type>? is undefined' do
        context 'authorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: true) }
          include_examples :update_singular_fallback, :related_record
        end

        context 'unauthorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: false) }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end
    end

    describe 'with "relation_type: :to_one" and records is nil' do
      let(:related_records_with_context) do
        [{
          relation_name: :author,
          relation_type: :to_one,
          records: nil
        }]
      end

      subject(:method_call) do
        lambda do
          authorizer.replace_fields(
            source_record: source_record,
            related_records_with_context: related_records_with_context
          )
        end
      end

      context 'authorized for remove_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, remove_author?: true, update?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for remove_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, remove_author?: false, update?: true) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for remove_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, remove_author?: true, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for remove_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, remove_author?: false, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'where remove_<type>? is undefined' do
        context 'authorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: true) }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: false) }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end
    end

    describe 'with "relation_type: :to_many"' do
      let(:related_records) { Array.new(3) { Comment.new } }
      let(:related_records_with_context) do
        [{
          relation_name: :comments,
          relation_type: :to_many,
          records: related_records
        }]
      end

      subject(:method_call) do
        lambda do
          authorizer.replace_fields(
            source_record: source_record,
            related_records_with_context: related_records_with_context
          )
        end
      end

      context 'authorized for update? on source record and related records is empty' do
        before { allow_action(ns_source, 'update?') }
        let(:related_records) { [] }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on source record  and related records is empty' do
        before { disallow_action(ns_source, 'update?') }
        let(:related_records) { [] }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for replace_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_comments?: true, update?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for replace_<type>? and authorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_comments?: false, update?: true) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for replace_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_comments?: true, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for replace_<type>? and unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, replace_comments?: false, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'where replace_<type>? is undefined' do
        context 'authorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: true) }
          include_examples :update_multiple_fallback, :related_records
        end

        context 'unauthorized for update? on source record' do
          before { stub_policy_actions(ns_source, update?: false) }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end
    end
  end

  describe '#create_resource' do
    describe 'with "relation_type: :to_one"' do
      let(:related_record) { User.new }
      let(:related_records_with_context) do
        [{
          relation_name: :author,
          relation_type: :to_one,
          records: related_record
        }]
      end
      let(:source_class) { source_record.class }
      let(:ns_source_class) { namespace + [source_class] }
      subject(:method_call) do
        lambda do
          authorizer.create_resource(
            source_class: source_class,
            related_records_with_context: related_records_with_context
          )
        end
      end

      context 'authorized for create? and authorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_author?: true, create?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for create? and unauthorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_author?: false, create?: true) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for create? and authorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_author?: true, create?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for create? and unauthorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_author?: false, create?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'where create_with_<type>? is undefined' do
        context 'authorized for create? on source class' do
          before { stub_policy_actions(ns_source_class, create?: true) }
          include_examples :update_singular_fallback, :related_record
        end

        context 'unauthorized for create? on source class' do
          before { stub_policy_actions(ns_source_class, create?: false) }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end
    end

    describe 'with "relation_type: :to_many"' do
      let(:related_records) { Array.new(3) { Comment.new } }
      let(:related_records_with_context) do
        [{
          relation_name: :comments,
          relation_type: :to_many,
          records: related_records
        }]
      end
      let(:source_class) { source_record.class }
      let(:ns_source_class) { namespace + [source_class] }
      subject(:method_call) do
        lambda do
          authorizer.create_resource(
            source_class: source_class,
            related_records_with_context: related_records_with_context
          )
        end
      end

      context 'authorized for create? on source class and related records is empty' do
        before { stub_policy_actions(ns_source_class, create?: true) }
        let(:related_records) { [] }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for create? and authorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_comments?: true, create?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for create? and unauthorized for create_with_<type>? on source class' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before { stub_policy_actions(ns_source_class, create_with_comments?: false, create?: true) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for create? on source class and related records is empty' do
        let(:related_records) { [] }
        before { stub_policy_actions(ns_source_class, create?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for create? and authorized for create_with_<type>? on source class' do
        before { stub_policy_actions(ns_source_class, create_with_comments?: true, create?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for create? and unauthorized for create_with_<type>? on source class' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before {
          stub_policy_actions(ns_source_class, create_with_comments?: false, create?: false)
        }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'where create_with_<type>? is undefined' do
        context 'authorized for create? on source class' do
          before { stub_policy_actions(ns_source_class, create?: true) }
          include_examples :update_multiple_fallback, :related_records
        end

        context 'unauthorized for create? on source class' do
          before { stub_policy_actions(ns_source_class, create?: false) }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end
    end
  end

  describe '#remove_resource' do
    subject(:method_call) do
      -> { authorizer.remove_resource(source_record: source_record) }
    end

    context 'authorized for destroy? on record' do
      before { allow_action(ns_source, 'destroy?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for destroy? on record' do
      before { disallow_action(ns_source, 'destroy?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#replace_to_one_relationship' do
    let(:related_record) { User.new }
    subject(:method_call) do
      lambda do
        authorizer.replace_to_one_relationship(
          source_record: source_record,
          new_related_record: related_record,
          relationship_type: :author
        )
      end
    end

    context 'authorized for replace_<type>? and update? on record' do
      before { stub_policy_actions(ns_source, replace_author?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_<type>? and authorized for update? on record' do
      before { stub_policy_actions(ns_source, replace_author?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for replace_<type>? and unauthorized for update? on record' do
      before { stub_policy_actions(ns_source, replace_author?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_<type>? and update? on record' do
      before { stub_policy_actions(ns_source, replace_author?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where replace_<type>? is undefined' do
      context 'authorized for update? on source record' do
        before { stub_policy_actions(ns_source, update?: true) }
        include_examples :update_singular_fallback, :related_record
      end

      context 'unauthorized for update? on source record' do
        before { stub_policy_actions(ns_source, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#create_to_many_relationship' do
    let(:related_records) { Array.new(3) { Comment.new } }
    subject(:method_call) do
      lambda do
        authorizer.create_to_many_relationship(
          source_record: source_record,
          new_related_records: related_records,
          relationship_type: :comments
        )
      end
    end

    context 'authorized for add_to_<type>? and update? on record' do
      before { stub_policy_actions(ns_source, add_to_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for add_to_<type>? and authorized for update? on record' do
      before { stub_policy_actions(ns_source, add_to_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for add_to_<type>? and unauthorized for update? on record' do
      before { stub_policy_actions(ns_source, add_to_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for add_to_<type>? and update? on record' do
      before { stub_policy_actions(ns_source, add_to_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where add_to_<type>? not defined' do
      context 'authorized for update? on record' do
        before { stub_policy_actions(ns_source, update?: true) }
        include_examples :update_multiple_fallback, :related_records
      end

      context 'unauthorized for update? on record' do
        before { stub_policy_actions(ns_source, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#replace_to_many_relationship' do
    let(:article) { articles(:article_with_comments) }
    let(:ns_article) { namespace + [article] }
    let(:new_comments) { Array.new(3) { Comment.new } }
    subject(:method_call) do
      lambda do
        authorizer.replace_to_many_relationship(
          source_record: article,
          new_related_records: new_comments,
          relationship_type: :comments
        )
      end
    end

    context 'authorized for replace_<type>? and update? on record' do
      before { stub_policy_actions(ns_article, replace_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_<type>? and authorized for update? on record' do
      before { stub_policy_actions(ns_article, replace_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for replace_<type>? and unauthorized for update? on record' do
      before { stub_policy_actions(ns_article, replace_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_<type>? and update? on record' do
      before { stub_policy_actions(ns_article, replace_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where replace_<type>? not defined' do
      context 'authorized for update? on record' do
        before { stub_policy_actions(ns_article, update?: true) }
        include_examples :update_multiple_fallback, :new_comments
      end

      context 'unauthorized for update? on record' do
        before { stub_policy_actions(ns_article, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#remove_to_many_relationship' do
    let(:article) { articles(:article_with_comments) }
    let(:ns_article) { namespace + [article] }
    let(:comments_to_remove) { article.comments.limit(2) }
    subject(:method_call) do
      lambda do
        authorizer.remove_to_many_relationship(
          source_record: article,
          related_records: comments_to_remove,
          relationship_type: :comments
        )
      end
    end

    context 'authorized for remove_from_<type>? and article? on article' do
      before { stub_policy_actions(ns_article, remove_from_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_from_<type>? and authorized for update? on article' do
      before { stub_policy_actions(ns_article, remove_from_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for remove_from_<type>? and unauthorized for update? on article' do
      before { stub_policy_actions(ns_article, remove_from_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_from_<type>? and update? on article' do
      before { stub_policy_actions(ns_article, remove_from_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where remove_from_<type>? not defined' do
      context 'authorized for update? on article' do
        before { stub_policy_actions(ns_article, update?: true) }
        include_examples :update_multiple_fallback, :comments_to_remove
      end

      context 'unauthorized for update? on article' do
        before { stub_policy_actions(ns_article, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#remove_to_one_relationship' do
    subject(:method_call) do
      lambda do
        authorizer.remove_to_one_relationship(
          source_record: source_record, relationship_type: :author
        )
      end
    end

    context 'authorized for remove_<type>? and article? on record' do
      before { stub_policy_actions(ns_source, remove_author?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_<type>? and authorized for update? on record' do
      before { stub_policy_actions(ns_source, remove_author?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for remove_<type>? and unauthorized for update? on record' do
      before { stub_policy_actions(ns_source, remove_author?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_<type>? and update? on record' do
      before { stub_policy_actions(ns_source, remove_author?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where remove_<type>? not defined' do
      context 'authorized for update? on record' do
        before { stub_policy_actions(ns_source, update?: true) }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on record' do
        before { stub_policy_actions(ns_source, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#include_has_many_resource' do
    let(:record_class) { Article }
    let(:source_record) { Comment.new }
    subject(:method_call) do
      lambda do
        authorizer.include_has_many_resource(
          source_record: source_record, record_class: record_class
        )
      end
    end

    context 'authorized for index? on record class' do
      before { allow_action(namespace + [record_class], 'index?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for index? on record class' do
      before { disallow_action(namespace + [record_class], 'index?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#include_has_one_resource' do
    let(:related_record) { Article.new }
    let(:source_record) { Comment.new }
    subject(:method_call) do
      lambda do
        authorizer.include_has_one_resource(
          source_record: source_record,
          related_record: related_record
        )
      end
    end

    context 'authorized for show? on record' do
      before { allow_action(namespace + [related_record], 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(namespace + [related_record], 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end
end
