require 'spec_helper'

RSpec.describe 'Relationship operations', type: :request do
  fixtures :all

  let(:article) { Article.all.sample }
  let(:policy_scope) { Article.none }

  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /articles/:id/relationships/comments' do
    let(:article) { articles(:article_with_comments) }
    let(:policy_scope) { Article.all }
    let(:comments_on_article) { article.comments }
    let(:comments_policy_scope) { comments_on_article.limit(1) }

    before do
      allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(comments_policy_scope)
    end
    subject(:last_response) { get("/articles/#{article.id}/relationships/comments") }

    context 'unauthorized for show_relationship' do
      before { disallow_operation('show_relationship', article, nil) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_relationship' do
      before { allow_operation('show_relationship', article, nil) }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by ArticlePolicy::Scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end

      it 'displays only comments allowed by CommentPolicy::Scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(comments_policy_scope.first.id.to_s)
      end
    end
  end

  describe 'GET /articles/:id/relationships/author' do
    subject(:last_response) { get("/articles/#{article.id}/relationships/author") }

    let(:article) { articles(:article_with_author) }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show_relationship' do
      before { disallow_operation('show_relationship', article, article.author) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_relationship' do
      before { allow_operation('show_relationship', article, article.author) }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'POST /articles/:id/relationships/comments' do
    let(:new_comments) { Array.new(2) { Comment.new }.each(&:save) }
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": [
          { "type": "comments", "id": "#{new_comments.first.id}" },
          { "type": "comments", "id": "#{new_comments.last.id}" }
        ]
      }
      EOS
    end
    subject(:last_response) { post("/articles/#{article.id}/relationships/comments", json) }
    let(:policy_scope) { Article.all }
    let(:comments_scope) { Comment.all }

    before do
      allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(comments_scope)
    end

    context 'unauthorized for create_to_many_relationship' do
      before { disallow_operation('create_to_many_relationship', article, new_comments) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create_to_many_relationship' do
      before { allow_operation('create_to_many_relationship', article, new_comments) }
      it { is_expected.to be_successful }

      context 'limited by policy scope on comments' do
        let(:comments_scope) { Comment.none }
        it { is_expected.to be_not_found }
      end

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope on articles' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'PATCH /articles/:id/relationships/comments' do
    context 'unauthorized for update? on article' do
      before { disallow_action('update?', article) }

      xcontext 'unauthorized for update? on comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on comments' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'unauthorized for update? on comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on comments' do
        it { is_expected.to be_created }
      end
    end
  end

  describe 'PATCH /articles/:id/relationships/author' do
    context 'unauthorized for update? on article' do
      before { disallow_action('update?', article) }

      xcontext 'unauthorized for update? on author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on author' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'unauthorized for update? on author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on author' do
        it { is_expected.to be_created }
      end
    end
  end

  describe 'DELETE /articles/:id/relationships/comments' do
    context 'unauthorized for update? on article' do
      before { disallow_action('update?', article) }

      xcontext 'unauthorized for update? on any of the comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on all the comments' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'unauthorized for update? on any of the comments' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on all the comments' do
        it { is_expected.to be_successful }
      end
    end
  end

  describe 'DELETE /articles/:id/relationships/author' do
    subject(:last_response) { delete("/articles/#{article.id}/relationships/author") }

    context 'unauthorized for update? on article' do
      before { disallow_action('update?', article) }

      xcontext 'unauthorized for update? on the author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on the author' do
        it { is_expected.to be_forbidden }
      end
    end

    context 'authorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'unauthorized for update? on the author' do
        it { is_expected.to be_forbidden }
      end

      xcontext 'authorized for update? on the author' do
        it { is_expected.to be_successful }
      end
    end
  end
end
