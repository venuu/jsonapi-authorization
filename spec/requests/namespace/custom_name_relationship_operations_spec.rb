require 'spec_helper'

RSpec.describe 'including custom name relationships', type: :request, pundit: "2.0" do
  include AuthorizationStubs
  fixtures :all

  subject { last_response }
  let(:json_included) { JSON.parse(last_response.body) }

  let(:comments_policy_scope) { Comment.all }

  before do
    allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(
      comments_policy_scope
    )
    allow_any_instance_of(CommentPolicy).to receive(:show?).and_return(true)
    allow_any_instance_of(UserPolicy).to receive(:show?).and_return(true)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET api/v1/comments/:id/reviewer' do
    subject(:last_response) { get("api/v1/comments/#{Comment.first.id}/reviewer") }
    context "access authorized" do
      before do
        allow_any_instance_of(Api::V1::CommentPolicy).to receive(:show?).and_return(true)
        allow_any_instance_of(Api::V1::UserPolicy).to receive(:show?).and_return(true)
      end
      it { is_expected.to be_ok }
    end

    context "access to reviewer forbidden" do
      before do
        allow_any_instance_of(Api::V1::CommentPolicy).to receive(:show?).and_return(true)
        allow_any_instance_of(Api::V1::UserPolicy).to receive(:show?).and_return(false)
      end
      it { is_expected.to be_forbidden }
    end
  end
end
