require 'spec_helper'

RSpec.describe 'including resources alongside normal operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  let(:article) { articles(:article_with_comments) }

  subject { last_response }
  let(:json_included) { JSON.parse(last_response.body)['included'] }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(Article.all)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  shared_examples_for :include_directive_tests do
    describe 'one-level deep has_many relationship' do
      let(:include_query) { 'comments' }

      let(:comments_policy_scope) { Comment.all }
      before do
        allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(comments_policy_scope)
      end

      context 'unauthorized for include_has_many_resource for Comment' do
        before { disallow_operation('include_has_many_resource', Comment, authorizer: chained_authorizer) }
        it { is_expected.to be_forbidden }
      end

      context 'authorized for include_has_many_resource for Comment' do
        before { allow_operation('include_has_many_resource', Comment, authorizer: chained_authorizer) }
        it { is_expected.to be_ok }

        let(:comments_policy_scope) { Comment.limit(1) }

        it 'includes only comments allowed by policy scope' do
          expect(json_included.length).to eq(1)
          expect(json_included.first["id"]).to eq(comments_policy_scope.first.id.to_s)
        end
      end
    end
  end

  describe 'GET /articles' do
    subject(:last_response) { get("/articles?include=#{include_query}") }
    let(:chained_authorizer) { allow_operation('find', Article) }

    include_examples :include_directive_tests
  end

  describe 'GET /articles/:id' do
    subject(:last_response) { get("/articles/#{article.id}?include=#{include_query}") }
    let(:chained_authorizer) { allow_operation('show', article) }

    include_examples :include_directive_tests
  end
end
