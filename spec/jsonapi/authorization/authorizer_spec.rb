require 'spec_helper'

RSpec.describe JSONAPI::Authorization::Authorizer do
  def allow_action(action, record)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to receive(:new).with(any_args, record) { double(action => true) }
  end

  def disallow_action(action, record)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to receive(:new).with(any_args, record) { double(action => false) }
  end

  before do
    source_authorizations.each do |action, retval|
      allow_any_instance_of(ArticlePolicy).to receive("#{action}?").and_return(retval)
    end

    if defined?(related_record) && defined?(related_authorizations)
      related_policy = ::Pundit.policy(nil, related_record).class
      related_authorizations.each do |action, retval|
        allow_any_instance_of(related_policy).to receive("#{action}?").and_return(retval)
      end
    end

    if defined?(related_records) && defined?(related_authorizations)
      related_policy = ::Pundit.policy(nil, related_records.first).class
      related_authorizations.each do |action, retval|
        allow_any_instance_of(related_policy).to receive("#{action}?").and_return(retval)
      end
    end
  end

  let(:source_record) { Article.new }
  let(:authorizer) { described_class.new({}) }

  describe '#find' do
    subject(:method_call) do
      -> { authorizer.find(source_record) }
    end

    context 'authorized for index? on record' do
      let(:source_authorizations) { {index: true} }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for index? on record' do
      let(:source_authorizations) { {index: false} }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show' do
    subject(:method_call) do
      -> { authorizer.show(source_record) }
    end

    context 'authorized for show? on record' do
      let(:source_authorizations) { {show: true} }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      let(:source_authorizations) { {show: false} }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#show_relationship' do
    subject(:method_call) do
      -> { authorizer.show_relationship(source_record, related_record) }
    end

    context 'authorized for show? on source record' do
      let(:source_authorizations) { {show: true} }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          let(:related_authorizations) { {show: true} }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          let(:related_authorizations) { {show: false} }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      let(:source_authorizations) { {show: false} }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          let(:related_authorizations) { {show: true} }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          let(:related_authorizations) { {show: false} }
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
      let(:source_authorizations) { {show: true} }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          let(:related_authorizations) { {show: true} }
          it { is_expected.not_to raise_error }
        end

        context 'unauthorized for show on related record' do
          let(:related_authorizations) { {show: false} }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end
      end

      context 'related record is nil' do
        let(:related_record) { nil }
        it { is_expected.not_to raise_error }
      end
    end

    context 'unauthorized for show? on source record' do
      let(:source_authorizations) { {show: false} }

      context 'related record is present' do
        let(:related_record) { Comment.new }

        context 'authorized for show on related record' do
          let(:related_authorizations) { {show: true} }
          it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
        end

        context 'unauthorized for show on related record' do
          let(:related_authorizations) { {show: false} }
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
      let(:source_authorizations) { {show: true} }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for show? on record' do
      let(:source_authorizations) { {show: false} }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end

  describe '#replace_fields' do
    let(:related_records) { Array.new(3) { Comment.new } }
    subject(:method_call) do
      -> { authorizer.replace_fields(source_record, related_records) }
    end

    context 'authorized for update? on source record' do
      let(:source_authorizations) { {update: true} }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for update? on all of the related records' do
        let(:related_authorizations) { {update: true} }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action('update?', related_records.first)
          disallow_action('update?', related_records.last)
        end

        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end

    context 'unauthorized for update? on source record' do
      let(:source_authorizations) { {update: false} }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for update? on all of the related records' do
        let(:related_authorizations) { {update: true} }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action('update?', related_records.first)
          disallow_action('update?', related_records.last)
        end

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

    context 'authorized for create? on source record' do
      let(:source_authorizations) { {create: true} }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.not_to raise_error }
      end

      context 'authorized for update? on all of the related records' do
        let(:related_authorizations) { {update: true} }
        it { is_expected.not_to raise_error }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action('update?', related_records.first)
          disallow_action('update?', related_records.last)
        end

        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end
    end

    context 'unauthorized for create? on source record' do
      let(:source_authorizations) { {create: false} }

      context 'related records is empty' do
        let(:related_records) { [] }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'authorized for update? on all of the related records' do
        let(:related_authorizations) { {update: true} }
        it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
      end

      context 'unauthorized for update? on any of the related records' do
        let(:related_records) { [Comment.new(id: 1), Comment.new(id: 2)] }
        before do
          allow_action('update?', related_records.first)
          disallow_action('update?', related_records.last)
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
      let(:source_authorizations) { {destroy: true} }
      it { is_expected.not_to raise_error }
    end

    context 'unauthorized for destroy? on record' do
      let(:source_authorizations) { {destroy: false} }
      it { is_expected.to raise_error(::Pundit::NotAuthorizedError) }
    end
  end
end
