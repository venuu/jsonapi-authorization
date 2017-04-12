require 'spec_helper'

RSpec.describe JSONAPI::Authorization::DefaultPunditAuthorizer do
  include PunditStubs
  fixtures :all

  let(:source_record) { Article.new }
  let(:authorizer) { described_class.new({}) }

  describe '#find' do
    subject(:method_call) do
      -> { authorizer.find(source_record) }
    end

    context 'authorized for index? on record' do
      before { allow_action(source_record, 'index?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for index? on record' do
      before { disallow_action(source_record, 'index?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show' do
    subject(:method_call) do
      -> { authorizer.show(source_record) }
    end

    context 'authorized for show? on record' do
      before { allow_action(source_record, 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(source_record, 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show_relationship' do
    subject(:method_call) do
      -> { authorizer.show_relationship(source_record, related_record) }
    end

    context 'authorized for show? on source record' do
      before { allow_action(source_record, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(related_record, 'show?') }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(related_record, 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      before { disallow_action(source_record, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(related_record, 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(related_record, 'show?') }
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
      -> { authorizer.show_related_resource(source_record, related_record) }
    end

    context 'authorized for show? on source record' do
      before { allow_action(source_record, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(related_record, 'show?') }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(related_record, 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      before { disallow_action(source_record, 'show?') }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          before { allow_action(related_record, 'show?') }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          before { disallow_action(related_record, 'show?') }
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
      -> { authorizer.show_related_resources(source_record) }
    end

    context 'authorized for show? on record' do
      before { allow_action(source_record, 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(source_record, 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#replace_fields' do
    let(:related_records) { Array.new(3) { Comment.new } }
    let(:related_records_with_context) do
      [{
        relation_name: :comments,
        relation_type: :to_many,
        records: related_records
      }]
    end

    subject(:method_call) do
      -> { authorizer.replace_fields(source_record, related_records_with_context) }
    end

    context 'authorized for update? on source record and related records is empty' do
      before { allow_action(source_record, 'update?') }
      let(:related_records) { [] }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for update? on source record  and related records is empty' do
      before { disallow_action(source_record, 'update?') }
      let(:related_records) { [] }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for replace_comments? and authorized for update? on source record' do
      before { stub_policy_actions(source_record, replace_comments?: true, update?: true) }
      it { is_expected.not_to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'unauthorized for replace_comments? and authorized for update? on source record' do
      before { stub_policy_actions(source_record, replace_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
    
    context 'authorized for replace_comments? and unauthorized for update? on source record' do
      before { stub_policy_actions(source_record, replace_comments?: true, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'unauthorized for replace_comments? and unauthorized for update? on source record' do
      before { stub_policy_actions(source_record, replace_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where replace_<type>? is undefined' do
      context 'authorized for update? on source record' do
        before { stub_policy_actions(source_record, update?: true) }
        it { is_expected.not_to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for update? on source record' do
        before { stub_policy_actions(source_record, update?: false) }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#create_resource' do
    let(:related_records) { Array.new(3) { Comment.new } }
    let(:source_class) { source_record.class }
    subject(:method_call) do
      -> { authorizer.create_resource(source_class, related_records) }
    end

    context 'authorized for create? on source class' do
      before { allow_action(source_class, 'create?') }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for update? on all of the related records' do
        before { related_records.each { |r| allow_action(r, 'update?') } }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action(related_records.first, 'update?')
          disallow_action(related_records.last, 'update?')
        end

        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end

    context 'unauthorized for create? on source class' do
      before { disallow_action(source_class, 'create?') }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for update? on all of the related records' do
        before { related_records.each { |r| allow_action(r, 'update?') } }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action(related_records.first, 'update?')
          disallow_action(related_records.last, 'update?')
        end

        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#remove_resource' do
    subject(:method_call) do
      -> { authorizer.remove_resource(source_record) }
    end

    context 'authorized for destroy? on record' do
      before { allow_action(source_record, 'destroy?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for destroy? on record' do
      before { disallow_action(source_record, 'destroy?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#replace_to_one_relationship' do
    let(:related_record) { User.new }
    subject(:method_call) do
      -> { authorizer.replace_to_one_relationship(source_record, related_record, :author) }
    end

    context 'authorized for replace_author? and update? on record' do
      before { stub_policy_actions(source_record, replace_author?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_author? and authorized for update? on record' do
      before { stub_policy_actions(source_record, replace_author?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for replace_author? and unauthorized for update? on record' do
      before { stub_policy_actions(source_record, replace_author?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_author? and update? on record' do
      before { stub_policy_actions(source_record, replace_author?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where replace_<type>? not defined' do
      # CommentPolicy does not define #replace_article?, so #update? should determine authorization
      let(:source_record) { comments(:comment_1) }
      let(:related_records) { Article.new }
      subject(:method_call) do
        -> { authorizer.replace_to_one_relationship(source_record, related_record, :article) }
      end

      context 'authorized for update? on record' do
        before { allow_action(source_record, 'update?') }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on record' do
        before { disallow_action(source_record, 'update?') }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#create_to_many_relationship' do
    let(:related_records) { Array.new(3) { Comment.new } }
    subject(:method_call) do
      -> { authorizer.create_to_many_relationship(source_record, related_records, :comments) }
    end

    context 'authorized for add_to_comments? and update? on record' do
      before { stub_policy_actions(source_record, add_to_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for add_to_comments? and authorized for update? on record' do
      before { stub_policy_actions(source_record, add_to_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for add_to_comments? and unauthorized for update? on record' do
      before { stub_policy_actions(source_record, add_to_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for add_to_comments? and update? on record' do
      before { stub_policy_actions(source_record, add_to_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where add_to_<type>? not defined' do
      # ArticlePolicy does not define #add_to_tags?, so #update? should determine authorization
      let(:related_records) { Array.new(3) { Tag.new } }
      subject(:method_call) do
        -> { authorizer.create_to_many_relationship(source_record, related_records, :tags) }
      end

      context 'authorized for update? on record' do
        before { allow_action(source_record, 'update?') }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on record' do
        before { disallow_action(source_record, 'update?') }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#replace_to_many_relationship' do
    let(:article) { articles(:article_with_comments) }
    let(:new_comments) { Array.new(3) { Comment.new } }
    subject(:method_call) do
      -> { authorizer.replace_to_many_relationship(article, new_comments, :comments) }
    end

    context 'authorized for replace_comments? and update? on record' do
      before { stub_policy_actions(article, replace_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_comments? and authorized for update? on record' do
      before { stub_policy_actions(article, replace_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for replace_comments? and unauthorized for update? on record' do
      before { stub_policy_actions(article, replace_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for replace_comments? and update? on record' do
      before { stub_policy_actions(article, replace_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where replace_<type>? not defined' do
      # ArticlePolicy does not define #replace_tags?, so #update? should determine authorization
      let(:new_tags) { Array.new(3) { Tag.new } }
      subject(:method_call) do
        -> { authorizer.replace_to_many_relationship(article, new_tags, :tags) }
      end

      context 'authorized for update? on record' do
        before { allow_action(article, 'update?') }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on record' do
        before { disallow_action(article, 'update?') }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#remove_to_many_relationship' do
    let(:article) { articles(:article_with_comments) }
    let(:comments_to_remove) { article.comments.limit(2) }
    subject(:method_call) do
      -> { authorizer.remove_to_many_relationship(article, comments_to_remove, :comments) }
    end

    context 'authorized for remove_from_comments? and article? on article' do
      before { stub_policy_actions(article, remove_from_comments?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_from_comments? and authorized for update? on article' do
      before { stub_policy_actions(article, remove_from_comments?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for remove_from_comments? and unauthorized for update? on article' do
      before { stub_policy_actions(article, remove_from_comments?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_from_comments? and update? on article' do
      before { stub_policy_actions(article, remove_from_comments?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where remove_from_<type>? not defined' do
      # ArticlePolicy does not define #remove_from_tags?, so #update? should determine authorization
      let(:tags_to_remove) { article.tags.limit(2) }
      subject(:method_call) do
        -> { authorizer.create_to_many_relationship(article, tags_to_remove, :tags) }
      end

      context 'authorized for update? on article' do
        before { allow_action(article, 'update?') }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on article' do
        before { disallow_action(article, 'update?') }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#remove_to_one_relationship' do
    subject(:method_call) do
      -> { authorizer.remove_to_one_relationship(source_record, :author) }
    end

    context 'authorized for remove_author? and article? on record' do
      before { stub_policy_actions(source_record, remove_author?: true, update?: true) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_author? and authorized for update? on record' do
      before { stub_policy_actions(source_record, remove_author?: false, update?: true) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'authorized for remove_author? and unauthorized for update? on record' do
      before { stub_policy_actions(source_record, remove_author?: true, update?: false) }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for remove_author? and update? on record' do
      before { stub_policy_actions(source_record, remove_author?: false, update?: false) }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end

    context 'where remove_<type>? not defined' do
      # CommentPolicy does not define #remove_article?, so #update? should determine authorization
      let(:source_record) { comments(:comment_1) }
      subject(:method_call) do
        -> { authorizer.remove_to_one_relationship(source_record, :article) }
      end

      context 'authorized for update? on record' do
        before { allow_action(source_record, 'update?') }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on record' do
        before { disallow_action(source_record, 'update?') }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end
  end

  describe '#include_has_many_resource' do
    let(:record_class) { Article }
    let(:source_record) { Comment.new }
    subject(:method_call) do
      -> { authorizer.include_has_many_resource(source_record, record_class) }
    end

    context 'authorized for index? on record class' do
      before { allow_action(record_class, 'index?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for index? on record class' do
      before { disallow_action(record_class, 'index?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#include_has_one_resource' do
    let(:related_record) { Article.new }
    let(:source_record) { Comment.new }
    subject(:method_call) do
      -> { authorizer.include_has_one_resource(source_record, related_record) }
    end

    context 'authorized for show? on record' do
      before { allow_action(related_record, 'show?') }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      before { disallow_action(related_record, 'show?') }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end
end
