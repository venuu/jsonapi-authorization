require 'spec_helper'

RSpec.describe JSONAPI::Authorization::Authorizer do
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
  end

  let(:source_record) { Article.new }
  let(:authorizer) { described_class.new({}) }

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
end
