require 'spec_helper'

RSpec.describe 'Related resources operations', type: :request do
  fixtures :all

  let(:article) { Article.all.sample }
  let(:authorizations) { {} }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    authorizations.each do |action, retval|
      allow_any_instance_of(ArticlePolicy).to receive("#{action}?").and_return(retval)
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

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }
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

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show?' do
      let(:authorizations) { {show: true} }

      context 'authorized for show? on author record' do
        let(:user_authorizations) { {show: true} }
        it { is_expected.to be_ok }
      end

      context 'unauthorized for show? on author record' do
        let(:user_authorizations) { {show: false} }
        it { is_expected.to be_forbidden }
      end

      context 'article has no author' do
        let(:article) { articles(:article_without_author) }

        it { is_expected.to be_ok }

        it 'responds with null data' do
          expect(json_data).to eq(nil)
        end
      end

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end
end
