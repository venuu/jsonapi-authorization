require 'spec_helper'

RSpec.describe 'Tricky operations', type: :request do
  fixtures :all

  let(:article) { Article.all.sample }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /articles/:id?includes=comments' do
    subject(:last_response) { get("/articles/#{article.id}?includes=comments") }
    let(:policy_scope) { Article.all }

    context 'authorized for show? on article' do
      before { allow_action('show?', article) }

      xit 'displays only comments allowed by CommentPolicy::Scope'
    end
  end

  describe 'POST /comments (with relationships link to articles)', pending: true do
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "type": "comments",
          "relationships": {
            "article": {
              "data": {
                "id": "1",
                "type": "articles"
              }
            }
          }
        }
      }
      EOS
    end

    context 'unauthorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'authorized for create? on comment' do
        # This is a tricky one. In real life, this is often something you may
        # want to permit. However, it is difficult to model with the typical
        # Pundit actions without knowing the particular use case

        it { is_expected.to be_forbidden }
      end
    end
  end

  describe 'PATCH /articles/:id (mass-modifying relationships)', pending: true do
    let(:existing) do
      Article.new(comments: Comment.where(id: 3))
    end

    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "id": "<<TODO>>"
          "type": "articles",
          "relationships": {
            "comments": {
              "data": [
                { "type": "comments", "id": "1" },
                { "type": "comments", "id": "2" }
              ]
            }
          }
        }
      }
      EOS
    end

    context 'authorized for update? on article' do
      before { allow_action('update?', article) }

      xcontext 'unauthorized for update? on comment 3' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'unauthorized for update? on comment 2' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'unauthorized for update? on comment 1' do
        it { is_expected.to be_forbidden }
      end
      xcontext 'authorized for update? on comments 1,2,3' do
        it { is_expected.to be_successful }
      end
    end
  end
end
