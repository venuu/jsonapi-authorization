require 'spec_helper'

RSpec.describe 'Related resources operations', type: :request do
  fixtures :all

  let(:article) { Article.all.sample }
  let(:authorizations) { {} }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    # TODO: improve faking of authorizer calls
    authorizer_double = double(:authorizer)
    allow_any_instance_of(JSONAPI::Authorization::PunditOperationsProcessor).to receive(:authorizer).and_return(authorizer_double)

    authorizations.each do |type, is_authorized|
      allow(authorizer_double).to receive(type).with(any_args) do
        raise Pundit::NotAuthorizedError unless is_authorized
      end
    end
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /articles/:id/comments' do
    let(:article) { articles(:article_with_comments) }
    let(:policy_scope) { Article.all }
    let(:comments_on_article) { article.comments }
    let(:comments_policy_scope) { comments_on_article.limit(1) }

    before do
      allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(comments_policy_scope)
      get("/articles/#{article.id}/comments")
    end

    context 'unauthorized for show_related_resources' do
      let(:authorizations) { {show_related_resources: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_related_resources' do
      let(:authorizations) { {show_related_resources: true} }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end

      it 'displays only comments allowed by CommentPolicy::Scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(comments_policy_scope.first.id.to_s)
      end
    end
  end

  describe 'GET /articles/:id/author' do
    let(:user_authorizations) { {} }
    before do
      user_authorizations.each do |action, retval|
        allow_any_instance_of(UserPolicy).to receive("#{action}?").and_return(retval)
      end
    end

    before { get("/articles/#{article.id}/author") }

    let(:article) { articles(:article_with_author) }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show_related_resource' do
      let(:authorizations) { {show_related_resource: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_related_resource' do
      let(:authorizations) { {show_related_resource: true} }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end
end
