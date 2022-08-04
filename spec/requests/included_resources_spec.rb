# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'including resources alongside normal operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  subject { last_response }
  let(:json_included) { JSON.parse(last_response.body)['included'] }

  let(:comments_policy_scope) { Comment.all }
  let(:article_policy_scope) { Article.all }
  let(:user_policy_scope) { User.all }

  # Take the stubbed scope and call merge(policy_scope.scope.all) so that the original
  # scope's conditions are not lost. Without it, the stub will always return all records
  # the user has access to regardless of context.
  before do
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve) do |policy_scope|
      article_policy_scope.merge(policy_scope.scope.all)
    end
    allow_any_instance_of(CommentPolicy::Scope).to receive(:resolve) do |policy_scope|
      comments_policy_scope.merge(policy_scope.scope.all)
    end
    allow_any_instance_of(UserPolicy::Scope).to receive(:resolve) do |policy_scope|
      user_policy_scope.merge(policy_scope.scope.all)
    end
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  shared_examples_for :include_directive_tests do
    describe 'one-level deep has_many relationship' do
      let(:include_query) { 'comments' }

      context 'unauthorized for include_has_many_resource for Comment', pending: 'Compatibility with JR 0.10' do
        before do
          disallow_operation(
            'include_has_many_resource',
            source_record: an_instance_of(Article),
            record_class: Comment,
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_forbidden }
      end

      context 'authorized for include_has_many_resource for Comment' do
        before do
          allow_operation(
            'include_has_many_resource',
            source_record: an_instance_of(Article),
            record_class: Comment,
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_successful }

        it 'includes only comments allowed by policy scope and associated with the article' do
          expect(json_included.length).to eq(article.comments.count)
          expect(
            json_included.map { |included| included["id"].to_i }
          ).to match_array(article.comments.map(&:id))
        end
      end
    end

    describe 'one-level deep has_one relationship' do
      let(:include_query) { 'author' }

      context 'unauthorized for include_has_one_resource for article.author', pending: 'Compatibility with JR 0.10' do
        before do
          disallow_operation(
            'include_has_one_resource',
            source_record: an_instance_of(Article),
            related_record: an_instance_of(User),
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_forbidden }
      end

      context 'authorized for include_has_one_resource for article.author' do
        before do
          allow_operation(
            'include_has_one_resource',
            source_record: an_instance_of(Article),
            related_record: an_instance_of(User),
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_successful }

        it 'includes the associated author resource' do
          json_users = json_included.select { |i| i['type'] == 'users' }
          expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
        end
      end
    end

    describe 'multiple one-level deep relationships' do
      let(:include_query) { 'author,comments' }

      context 'unauthorized for include_has_one_resource for article.author', pending: 'Compatibility with JR 0.10' do
        before do
          disallow_operation(
            'include_has_one_resource',
            source_record: an_instance_of(Article),
            related_record: an_instance_of(User),
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_forbidden }
      end

      context 'unauthorized for include_has_many_resource for Comment', pending: 'Compatibility with JR 0.10' do
        before do
          allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer)
          disallow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_forbidden }
      end

      context 'authorized for both operations' do
        before do
          allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer)
          allow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_successful }

        it 'includes only comments allowed by policy scope and associated with the article' do
          json_comments = json_included.select { |item| item['type'] == 'comments' }
          expect(json_comments.length).to eq(article.comments.count)
          expect(
            json_comments.map { |i| i['id'] }
          ).to match_array(article.comments.pluck(:id).map(&:to_s))
        end

        it 'includes the associated author resource' do
          json_users = json_included.select { |item| item['type'] == 'users' }
          expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
        end
      end
    end

    describe 'a deep relationship' do
      let(:include_query) { 'author.comments' }

      context 'unauthorized for first relationship', pending: 'Compatibility with JR 0.10' do
        before do
          disallow_operation(
            'include_has_one_resource',
            source_record: an_instance_of(Article),
            related_record: an_instance_of(User),
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_forbidden }
      end

      context 'authorized for first relationship' do
        before { allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer) }

        context 'unauthorized for second relationship', pending: 'Compatibility with JR 0.10' do
          before { disallow_operation('include_has_many_resource', source_record: an_instance_of(User), record_class: Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_forbidden }
        end

        context 'authorized for second relationship' do
          before { allow_operation('include_has_many_resource', source_record: an_instance_of(User), record_class: Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_successful }

          it 'includes the first level resource' do
            json_users = json_included.select { |item| item['type'] == 'users' }
            expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
          end

          describe 'second level resources' do
            it 'includes only resources allowed by policy scope' do
              second_level_items = json_included.select { |item| item['type'] == 'comments' }
              expect(second_level_items.length).to eq(article.author.comments.count)
              expect(
                second_level_items.map { |i| i['id'] }
              ).to match_array(article.author.comments.pluck(:id).map(&:to_s))
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

        context 'unauthorized for first relationship', pending: 'Compatibility with JR 0.10' do
          before { disallow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Article, authorizer: chained_authorizer) }

          it { is_expected.to be_forbidden }
        end

        context 'authorized for first relationship' do
          before { allow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Article, authorizer: chained_authorizer) }

          it { is_expected.to be_successful }
        end
      end
    end
  end

  shared_examples_for :scope_limited_directive_tests do
    describe 'one-level deep has_many relationship' do
      let(:comments_policy_scope) { Comment.where(id: article.comments.first.id) }
      let(:include_query) { 'comments' }

      context 'authorized for include_has_many_resource for Comment' do
        before do
          allow_operation(
            'include_has_many_resource',
            source_record: an_instance_of(Article),
            record_class: Comment,
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_successful }

        it 'includes only comments allowed by policy scope' do
          expect(json_included.length).to eq(comments_policy_scope.length)
          expect(json_included.first["id"]).to eq(comments_policy_scope.first.id.to_s)
        end
      end
    end

    describe 'multiple one-level deep relationships' do
      let(:include_query) { 'author,comments' }
      let(:comments_policy_scope) { Comment.where(id: article.comments.first.id) }

      context 'authorized for both operations' do
        before do
          allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer)
          allow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_successful }

        it 'includes only comments allowed by policy scope and associated with the article' do
          json_comments = json_included.select { |item| item['type'] == 'comments' }
          expect(json_comments.length).to eq(comments_policy_scope.length)
          expect(
            json_comments.map { |i| i['id'] }
          ).to match_array(comments_policy_scope.pluck(:id).map(&:to_s))
        end

        it 'includes the associated author resource' do
          json_users = json_included.select { |item| item['type'] == 'users' }
          expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
        end
      end
    end

    describe 'a deep relationship' do
      let(:include_query) { 'author.comments' }
      let(:comments_policy_scope) { Comment.where(id: article.author.comments.first.id) }

      context 'authorized for first relationship' do
        before { allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer) }

        context 'authorized for second relationship' do
          before { allow_operation('include_has_many_resource', source_record: an_instance_of(User), record_class: Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_successful }

          it 'includes the first level resource' do
            json_users = json_included.select { |item| item['type'] == 'users' }
            expect(json_users).to include(a_hash_including('id' => article.author.id.to_s))
          end

          describe 'second level resources' do
            it 'includes only resources allowed by policy scope' do
              second_level_items = json_included.select { |item| item['type'] == 'comments' }
              expect(second_level_items.length).to eq(comments_policy_scope.length)
              expect(
                second_level_items.map { |i| i['id'] }
              ).to match_array(comments_policy_scope.pluck(:id).map(&:to_s))
            end
          end
        end
      end
    end
  end

  shared_examples_for :scope_limited_directive_test_modify_relationships do
    describe 'one-level deep has_many relationship' do
      let(:comments_policy_scope) { Comment.where(id: existing_comments.first.id) }
      let(:include_query) { 'comments' }

      context 'authorized for include_has_many_resource for Comment' do
        before do
          allow_operation(
            'include_has_many_resource',
            source_record: an_instance_of(Article),
            record_class: Comment,
            authorizer: chained_authorizer
          )
        end

        it { is_expected.to be_not_found }
      end
    end

    describe 'multiple one-level deep relationships' do
      let(:include_query) { 'author,comments' }
      let(:comments_policy_scope) { Comment.where(id: existing_comments.first.id) }

      context 'authorized for both operations' do
        before do
          allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer)
          allow_operation('include_has_many_resource', source_record: an_instance_of(Article), record_class: Comment, authorizer: chained_authorizer)
        end

        it { is_expected.to be_not_found }
      end
    end

    describe 'a deep relationship' do
      let(:include_query) { 'author.comments' }
      let(:comments_policy_scope) { Comment.where(id: existing_author.comments.first.id) }

      context 'authorized for first relationship' do
        before { allow_operation('include_has_one_resource', source_record: an_instance_of(Article), related_record: an_instance_of(User), authorizer: chained_authorizer) }

        context 'authorized for second relationship' do
          before { allow_operation('include_has_many_resource', source_record: an_instance_of(User), record_class: Comment, authorizer: chained_authorizer) }

          it { is_expected.to be_not_found }
        end
      end
    end
  end

  describe 'GET /articles' do
    subject(:last_response) { get("/articles?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('find', source_class: Article) }

    let(:article) do
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    end

    let(:article_policy_scope) { Article.where(id: article.id) }

    # TODO: Test properly with multiple articles, not just one.
    include_examples :include_directive_tests
    include_examples :scope_limited_directive_tests
  end

  describe 'GET /articles/:id' do
    let(:article) do
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    end

    subject(:last_response) { get("/articles/#{article.external_id}?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show', source_record: article) }

    include_examples :include_directive_tests
    include_examples :scope_limited_directive_tests
  end

  describe 'PATCH /articles/:id' do
    let(:article) do
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    end

    let(:attributes_json) { '{}' }
    let(:json) do
      <<-JSON.strip_heredoc
      {
        "data": {
          "type": "articles",
          "id": "#{article.external_id}",
          "attributes": #{attributes_json}
        }
      }
      JSON
    end
    subject(:last_response) { patch("/articles/#{article.external_id}?include=#{include_query}", json) }
    let!(:chained_authorizer) { allow_operation('replace_fields', source_record: article, related_records_with_context: []) }

    include_examples :include_directive_tests
    include_examples :scope_limited_directive_tests

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
    let(:related_records_with_context) do
      [
        {
          relation_type: :to_one,
          relation_name: :author,
          records: existing_author
        },
        {
          relation_type: :to_many,
          relation_name: :comments,
          # Relax the constraints of expected records here. Lower level tests modify the
          # available policy scope for comments, so we will get a different amount of records deep
          # down in the other specs.
          #
          # This is fine, because we test resource create relationships with specific matcher
          records: kind_of(Enumerable)
        }
      ]
    end

    let(:attributes_json) { '{}' }
    let(:json) do
      <<-JSON.strip_heredoc
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
      JSON
    end
    let(:article) { existing_author.articles.first }

    subject(:last_response) { post("/articles?include=#{include_query}", json) }
    let!(:chained_authorizer) do
      allow_operation(
        'create_resource',
        source_class: Article,
        related_records_with_context: related_records_with_context
      )
    end

    include_examples :include_directive_tests
    include_examples :scope_limited_directive_test_modify_relationships

    context 'the request has already failed validations' do
      let(:include_query) { 'author.comments' }
      let(:attributes_json) { '{ "blank-value": "indifferent" }' }

      it 'does not run include authorizations and fails with validation error' do
        expect(last_response).to be_unprocessable
      end
    end
  end

  describe 'GET /articles/:id/articles' do
    let(:article) do
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    end

    let(:article_policy_scope) { Article.where(id: article.id) }

    subject(:last_response) { get("/articles/#{article.external_id}/articles?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show_related_resources', source_record: article, related_record_class: article.class) }

    include_examples :include_directive_tests
    include_examples :scope_limited_directive_tests
  end

  describe 'GET /articles/:id/article', pending: true do
    let(:article) do
      Article.create(
        external_id: "indifferent_external_id",
        author: User.create(
          comments: Array.new(2) { Comment.create }
        ),
        comments: Array.new(2) { Comment.create }
      )
    end

    subject(:last_response) { get("/articles/#{article.external_id}/article?include=#{include_query}") }
    let!(:chained_authorizer) { allow_operation('show_related_resource', source_record: article, related_record: article) }

    include_examples :include_directive_tests
    include_examples :scope_limited_directive_tests
  end
end
