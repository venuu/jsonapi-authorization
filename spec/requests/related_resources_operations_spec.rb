require 'spec_helper'

RSpec.describe 'Related resources operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  let(:article) { Article.all.sample }
  let(:authorizations) { {} }
  let(:policy_scope) { Article.none }

  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /articles/:id/comments' do
    subject(:last_response) { get("/articles/#{article.external_id}/comments") }
    let(:article) { articles(:article_with_comments) }

    let(:policy_scope) { Article.all }
    let(:comments_on_article) { article.comments }
    let(:comments_policy_scope) { comments_on_article.limit(1) }

    before do
      allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(comments_policy_scope)
    end

    context 'unauthorized for show_related_resources' do
      before { disallow_operation('show_related_resources', article) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_related_resources' do
      before { allow_operation('show_related_resources', article) }
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
    subject(:last_response) { get("/articles/#{article.external_id}/author") }
    let(:article) { articles(:article_with_author) }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show_related_resource' do
      before { disallow_operation('show_related_resource', article, article.author) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_related_resource' do
      before { allow_operation('show_related_resource', article, article.author) }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end
end
