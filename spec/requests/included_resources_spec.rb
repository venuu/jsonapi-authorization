require 'spec_helper'

RSpec.describe 'including resources alongside normal operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  subject { last_response }
  let(:json_included) { JSON.parse(last_response.body)['included'] }

  let(:comments_policy_scope) { Comment.none }
  let(:article_policy_scope) { Article.all }

  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(
      article_policy_scope
    )
    allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve).and_return(
      comments_policy_scope
    )
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  shared_examples_for :include_directive_tests do
    describe 'one-level deep has_many relationship' do
      let(:include_query) { 'comments' }

      let(:comments_policy_scope) { Comment.all }

      context 'unauthorized for include_has_many_resource for Comment' do
        before { disallow_operation('include_has_many_resource', an_instance_of(Article), Comment, authorizer: chained_authorizer) }

        it { is_expected.to be_forbidden }
      end

      context 'authorized for include_has_many_resource for Comment' do
        before { allow_operation('include_has_many_resource', an_instance_of(Article), Comment, authorizer: chained_authorizer) }

        it { is_expected.to be_successful }

        let(:comments_policy_scope) { Comment.limit(1) }

        it 'includes only comments allowed by policy scope' do
          expect(json_included.length).to eq(1)
          expect(json_included.first["id"]).to eq(comments_policy_scope.first.id.to_s)
        end
      end
    end

    describe 'one-level deep has_one relationship' do
      let(:include_query) { 'author' }

      context 'unauthorized for include_has_one_resource for article.author' do
        before { disallow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer) }

        it { is_expected.to be_forbidden }
      end

      context 'authorized for include_has_one_resource for article.author' do
        before { allow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer) }

        it { is_expected.to be_successful }

        it 'includes the associated author resource' do
          json_users = json_included.select { |i| i['type'] == 'users' }
          expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
        end
      end
    end

    describe 'multiple one-level deep relationships' do
      let(:include_query) { 'author,comments' }
      let(:comments_policy_scope) { Comment.all }

      context 'unauthorized for include_has_one_resource for article.author' do
        before do
          disallow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer)
        end

        it { is_expected.to be_forbidden }
      end

      context 'unauthorized for include_has_many_resource for Comment' do
        before do
          allow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer)
          disallow_operation('include_has_many_resource', an_instance_of(Article), Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_forbidden }
      end

      context 'authorized for both operations' do
        before do
          allow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer)
          allow_operation('include_has_many_resource', an_instance_of(Article), Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_successful }

        let(:comments_policy_scope) { Comment.limit(1) }

        it 'includes only comments allowed by policy scope' do
          json_comments = json_included.select { |item| item['type'] == 'comments' }
          expect(json_comments.length).to eq(comments_policy_scope.length)
          expect(json_comments.map { |i| i['id'] }).to eq(comments_policy_scope.pluck(:id).map(&:to_s))
        end

        it 'includes the associated author resource' do
          json_users = json_included.select { |item| item['type'] == 'users' }
          expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
        end
      end
    end

    describe 'a deep relationship' do
      let(:include_query) { 'author.comments' }

      context 'unauthorized for first relationship' do
        before { disallow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer) }

        it { is_expected.to be_forbidden }
      end

      context 'authorized for first relationship' do
        before { allow_operation('include_has_one_resource', an_instance_of(Article), an_instance_of(User), authorizer: chained_authorizer) }

        context 'unauthorized for second relationship' do
          before { disallow_operation('include_has_many_resource', an_instance_of(User), Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_forbidden }
        end

        context 'authorized for second relationship' do
          before { allow_operation('include_has_many_resource', an_instance_of(User), Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_successful }

          let(:comments_policy_scope) { Comment.all }

          it 'includes the first level resource' do
            json_users = json_included.select { |item| item['type'] == 'users' }
            expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
          end

          describe 'second level resources' do
            let(:comments_policy_scope) { Comment.limit(1) }

            it 'includes only resources allowed by policy scope' do
              second_level_items = json_included.select { |item| item['type'] == 'comments' }
              expect(second_level_items.length).to eq(comments_policy_scope.length)
              expect(second_level_items.map { |i| i['id'] }).to eq(comments_policy_scope.pluck(:id).map(&:to_s))
            end
          end
        end
      end
    end

    describe 'a deep relationship with empty relations' do
      context 'first level has_one is nil' do
        let(:include_query) { 'non-existing-article.comments' }

        it { is_expected.to be_successful }
      end

      context 'first level has_many is empty' do
        let(:include_query) { 'empty-articles.comments' }

        context 'unauthorized for first relationship' do
          before { disallow_operation('include_has_many_resource', an_instance_of(Article), Article, authorizer: chained_authorizer) }

          it { is_expected.to be_forbidden }
        end

        context 'authorized for first relationship' do
          before { allow_operation('include_has_many_resource', an_instance_of(Article), Article, authorizer: chained_authorizer) }

          it { is_expected.to be_successful }
        end
      end
    end
  end

  describe 'GET /articles' do
    subject(:last_response) { get("/articles?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('find', Article) }

    let(:article) {
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    }

    let(:article_policy_scope) { Article.where(id: article.id) }

    # TODO: Test properly with multiple articles, not just one.
    include_examples :include_directive_tests
  end

  describe 'GET /articles/:id' do
    let(:article) {
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    }

    subject(:last_response) { get("/articles/#{article.external_id}?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show', article) }

    include_examples :include_directive_tests
  end

  describe 'PATCH /articles/:id' do
    let(:article) {
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    }

    let(:attributes_json) { '{}' }
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "type": "articles",
          "id": "#{article.external_id}",
          "attributes": #{attributes_json}
        }
      }
      EOS
    end
    subject(:last_response) { patch("/articles/#{article.external_id}?include=#{include_query}", json) }
    let!(:chained_authorizer) { allow_operation('replace_fields', article, []) }

    include_examples :include_directive_tests

    context 'the request has already failed validations' do
      let(:include_query) { 'author.comments' }
      let(:attributes_json) { '{ "blank-value": "indifferent" }' }

      it 'does not run include authorizations and fails with validation error' do
        expect(last_response).to be_unprocessable
      end
    end
  end

  describe 'POST /articles/:id' do
    let(:existing_author) do
      User.create(
        comments: Array.new(2) { Comment.create }
      )
    end
    let(:existing_comments) do
      Array.new(2) { Comment.create }
    end

    let(:attributes_json) { '{}' }
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "type": "articles",
          "id": "indifferent_external_id",
          "attributes": #{attributes_json},
          "relationships": {
            "comments": {
              "data": [
                { "type": "comments", "id": "#{existing_comments.first.id}" },
                { "type": "comments", "id": "#{existing_comments.second.id}" }
              ]
            },
            "author": {
              "data": {
                "type": "users", "id": "#{existing_author.id}"
              }
            }
          }
        }
      }
      EOS
    end
    let(:article) { existing_author.articles.first }

    subject(:last_response) { post("/articles?include=#{include_query}", json) }
    let!(:chained_authorizer) do
      allow_operation('create_resource', Article, [existing_author, *existing_comments])
    end

    include_examples :include_directive_tests

    context 'the request has already failed validations' do
      let(:include_query) { 'author.comments' }
      let(:attributes_json) { '{ "blank-value": "indifferent" }' }

      it 'does not run include authorizations and fails with validation error' do
        expect(last_response).to be_unprocessable
      end
    end
  end

  describe 'GET /articles/:id/articles' do
    let(:article) {
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    }

    let(:article_policy_scope) { Article.where(id: article.id) }

    subject(:last_response) { get("/articles/#{article.external_id}/articles?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show_related_resources', article) }

    include_examples :include_directive_tests
  end

  describe 'GET /articles/:id/article' do
    let(:article) {
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    }

    subject(:last_response) { get("/articles/#{article.external_id}/article?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show_related_resource', article, article) }

    include_examples :include_directive_tests
  end
end
