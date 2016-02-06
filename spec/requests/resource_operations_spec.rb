require 'spec_helper'

describe 'Resource operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  let(:article) { Article.all.sample }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_body) { JSON.parse(last_response.body) }
  let(:json_data) { json_body["data"] }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /articles' do
    subject(:last_response) { get('/articles') }

    context 'unauthorized for find' do
      before { disallow_operation('find', Article) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for find' do
      before { allow_operation('find', Article) }
      let(:policy_scope) { Article.where(id: article.id) }

      it { is_expected.to be_ok }

      it 'returns results limited by policy scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(article.id.to_s)
      end
    end

    describe 'with ?include=comments' do
      subject(:last_response) { get('/articles?include=comments') }
      let(:chained_authorizer) { allow_operation('find', Article) }
      let(:policy_scope) { Article.all }
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
          expect(json_body['included'].length).to eq(1)
          expect(json_body['included'].first["id"]).to eq(comments_policy_scope.first.id.to_s)
        end
      end
    end
  end

  describe 'GET /articles/:id' do
    subject(:last_response) { get("/articles/#{article.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show' do
      before { disallow_operation('show', article) }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for show' do
      before { allow_operation('show', article) }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'POST /articles' do
    subject(:last_response) { post("/articles", '{ "data": { "type": "articles" } }') }

    context 'unauthorized for create_resource' do
      before { disallow_operation('create_resource', Article, []) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create_resource' do
      before { allow_operation('create_resource', Article, []) }
      it { is_expected.to be_successful }
    end
  end

  describe 'PATCH /articles/:id' do
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "id": "#{article.id}",
          "type": "articles"
        }
      }
      EOS
    end

    subject(:last_response) { patch("/articles/#{article.id}", json) }
    let(:policy_scope) { Article.all }

    context 'authorized for replace_fields' do
      before { allow_operation('replace_fields', article, []) }
      it { is_expected.to be_successful }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'unauthorized for replace_fields' do
      before { disallow_operation('replace_fields', article, []) }
      it { is_expected.to be_forbidden }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'DELETE /articles/:id' do
    subject(:last_response) { delete("/articles/#{article.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for remove_resource' do
      before { disallow_operation('remove_resource', article) }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for remove_resource' do
      before { allow_operation('remove_resource', article) }
      it { is_expected.to be_successful }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end
end
