require 'spec_helper'

RSpec.describe 'Relationship operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  let(:article) { Article.all.sample }
  let(:policy_scope) { Article.none }

  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    allow_any_instance_of(Api::V1::ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET api/v1/articles/:id/relationships/comments' do
    let(:article) { articles(:article_with_comments) }
    let(:policy_scope) { Article.all }
    let(:comments_on_article) { article.comments }
    let(:comments_policy_scope) { comments_on_article.limit(1) }

    before do
      allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(comments_policy_scope)
    end
    subject(:last_response) { get("api/v1/articles/#{article.external_id}/relationships/comments") }

    context 'unauthorized for show_relationship' do
      before { disallow_operation('show_relationship', source_record: article, related_record: nil) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_relationship' do
      before { allow_operation('show_relationship', source_record: article, related_record: nil) }
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

  describe 'GET api/v1/articles/:id/relationships/author' do
    subject(:last_response) { get("api/v1/articles/#{article.external_id}/relationships/author") }

    let(:article) { articles(:article_with_author) }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show_relationship' do
      before { disallow_operation('show_relationship', source_record: article, related_record: article.author) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for show_relationship' do
      before { allow_operation('show_relationship', source_record: article, related_record: article.author) }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'POST api/v1/articles/:id/relationships/comments' do
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
    subject(:last_response) { post("api/v1/articles/#{article.external_id}/relationships/comments", json) }
    let(:policy_scope) { Article.all }
    let(:comments_scope) { Comment.all }

    before do
      allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(comments_scope)
    end

    context 'unauthorized for create_to_many_relationship' do
      before {
        disallow_operation(
          'create_to_many_relationship',
          source_record: article,
          new_related_records: new_comments,
          relationship_type: :comments
        )
      }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create_to_many_relationship' do
      before {
        allow_operation(
          'create_to_many_relationship',
          source_record: article,
          new_related_records: new_comments,
          relationship_type: :comments
        )
      }
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

  describe 'PATCH api/v1/articles/:id/relationships/comments' do
    let(:article) { articles(:article_with_comments) }
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
    subject(:last_response) { patch("api/v1/articles/#{article.external_id}/relationships/comments", json) }
    let(:policy_scope) { Article.all }
    let(:comments_scope) { Comment.all }

    before do
      allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(comments_scope)
    end

    context 'unauthorized for replace_to_many_relationship' do
      before do
        disallow_operation('replace_to_many_relationship', source_record: article, new_related_records: new_comments, relationship_type: :comments)
      end

      it { is_expected.to be_forbidden }
    end

    context 'authorized for replace_to_many_relationship' do
      context 'not limited by policy scopes' do
        before do
          allow_operation('replace_to_many_relationship', source_record: article, new_related_records: new_comments, relationship_type: :comments)
        end

        it { is_expected.to be_successful }
      end

      context 'limited by policy scope on comments' do
        let(:comments_scope) { Comment.none }
        before do
          allow_operation('replace_to_many_relationship', source_record: article, new_related_records: new_comments, relationship_type: :comments)
        end

        it do
          pending 'TODO: Maybe this actually should be succesful?'
          is_expected.to be_not_found
        end
      end

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope on articles' do
        before do
          allow_operation(
            'replace_to_many_relationship',
            source_record: article,
            new_related_records: new_comments,
            relationship_type: :comments
          )
        end
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'PATCH api/v1/articles/:id/relationships/author' do
    subject(:last_response) { patch("api/v1/articles/#{article.external_id}/relationships/author", json) }

    let(:article) { articles(:article_with_author) }
    let!(:old_author) { article.author }
    let(:policy_scope) { Article.all }
    let(:user_policy_scope) { User.all }

    before do
      allow_any_instance_of(Api::V1::UserPolicy::Scope).to receive(:resolve).and_return(user_policy_scope)
    end

    describe 'when replacing with a new author' do
      let(:new_author) { User.create }
      let(:json) do
        <<-EOS.strip_heredoc
        {
          "data": {
            "type": "users",
            "id": "#{new_author.id}"
          }
        }
        EOS
      end

      context 'unauthorized for replace_to_one_relationship' do
        before { disallow_operation('replace_to_one_relationship', source_record: article, new_related_record: new_author, relationship_type: :author) }
        it { is_expected.to be_forbidden }
      end

      context 'authorized for replace_to_one_relationship' do
        before { allow_operation('replace_to_one_relationship', source_record: article, new_related_record: new_author, relationship_type: :author) }
        it { is_expected.to be_successful }

        context 'limited by policy scope on author', skip: 'DISCUSS' do
          before do
            allow_any_instance_of(Api::V1::UserPolicy::Scope).to receive(:resolve).and_return(user_policy_scope)
          end
          let(:user_policy_scope) { User.where.not(id: article.author.id) }
          it { is_expected.to be_not_found }
        end

        # If this happens in real life, it's mostly a bug. We want to document the
        # behaviour in that case anyway, as it might be surprising.
        context 'limited by policy scope on article' do
          let(:policy_scope) { Article.where.not(id: article.id) }
          it { is_expected.to be_not_found }
        end
      end
    end

    describe 'when nullifying the author' do
      let(:new_author) { nil }
      let(:json) { '{ "data": null }' }

      context 'unauthorized for remove_to_one_relationship' do
        before { disallow_operation('remove_to_one_relationship', source_record: article, relationship_type: :author) }
        it { is_expected.to be_forbidden }
      end

      context 'authorized for remove_to_one_relationship' do
        before { allow_operation('remove_to_one_relationship', source_record: article, relationship_type: :author) }
        it { is_expected.to be_successful }

        context 'limited by policy scope on author', skip: 'DISCUSS' do
          let(:user_policy_scope) { User.where.not(id: article.author.id) }
          it { is_expected.to be_not_found }
        end

        # If this happens in real life, it's mostly a bug. We want to document the
        # behaviour in that case anyway, as it might be surprising.
        context 'limited by policy scope on article' do
          let(:policy_scope) { Article.where.not(id: article.id) }
          it { is_expected.to be_not_found }
        end
      end
    end
  end

  # Polymorphic has-one relationship replacing
  describe 'PATCH api/v1/tags/:id/relationships/taggable' do
    subject(:last_response) { patch("api/v1/tags/#{tag.id}/relationships/taggable", json) }

    let!(:old_taggable) { Comment.create }
    let!(:tag) { Tag.create(taggable: old_taggable) }
    let(:policy_scope) { Article.all }
    let(:comment_policy_scope) { Article.all }
    let(:tag_policy_scope) { Tag.all }

    before do
      allow_any_instance_of(Api::V1::TagPolicy::Scope).to receive(:resolve).and_return(tag_policy_scope)
      allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(comment_policy_scope)
    end

    describe 'when replacing with a new taggable' do
      let!(:new_taggable) { Article.create(external_id: 'new-article-id') }
      let(:json) do
        <<-EOS.strip_heredoc
        {
          "data": {
            "type": "articles",
            "id": "#{new_taggable.external_id}"
          }
        }
        EOS
      end

      context 'unauthorized for replace_to_one_relationship' do
        before {
          disallow_operation(
            'replace_to_one_relationship',
            source_record: tag,
            new_related_record: new_taggable,
            relationship_type: :taggable
          )
        }
        it { is_expected.to be_forbidden }
      end

      context 'authorized for replace_to_one_relationship' do
        before {
          allow_operation(
            'replace_to_one_relationship',
            source_record: tag,
            new_related_record: new_taggable,
            relationship_type: :taggable
          )
        }
        it { is_expected.to be_successful }

        context 'limited by policy scope on taggable', skip: 'DISCUSS' do
          let(:policy_scope) { Article.where.not(id: tag.taggable.id) }
          it { is_expected.to be_not_found }
        end

        # If this happens in real life, it's mostly a bug. We want to document the
        # behaviour in that case anyway, as it might be surprising.
        context 'limited by policy scope on tag' do
          let(:tag_policy_scope) { Tag.where.not(id: tag.id) }
          it { is_expected.to be_not_found }
        end
      end
    end

    # https://github.com/cerebris/jsonapi-resources/issues/1081
    describe 'when nullifying the taggable', skip: 'Broken upstream' do
      let(:new_taggable) { nil }
      let(:json) { '{ "data": null }' }

      context 'unauthorized for remove_to_one_relationship' do
        before { disallow_operation('remove_to_one_relationship', source_record: tag, relationship_type: :taggable) }
        it { is_expected.to be_forbidden }
      end

      context 'authorized for remove_to_one_relationship' do
        before { allow_operation('remove_to_one_relationship', source_record: tag, relationship_type: :taggable) }
        it { is_expected.to be_successful }

        context 'limited by policy scope on taggable', skip: 'DISCUSS' do
          let(:policy_scope) { Article.where.not(id: tag.taggable.id) }
          it { is_expected.to be_not_found }
        end

        # If this happens in real life, it's mostly a bug. We want to document the
        # behaviour in that case anyway, as it might be surprising.
        context 'limited by policy scope on tag' do
          let(:tag_policy_scope) { Tag.where.not(id: tag.id) }
          it { is_expected.to be_not_found }
        end
      end
    end
  end

  describe 'DELETE api/v1/articles/:id/relationships/comments' do
    let(:article) { articles(:article_with_comments) }
    let(:comments_to_remove) { article.comments.limit(2) }
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": [
          { "type": "comments", "id": "#{comments_to_remove.first.id}" },
          { "type": "comments", "id": "#{comments_to_remove.last.id}" }
        ]
      }
      EOS
    end
    subject(:last_response) { delete("api/v1/articles/#{article.external_id}/relationships/comments", json) }
    let(:policy_scope) { Article.all }
    let(:comments_scope) { Comment.all }

    before do
      allow_any_instance_of(Api::V1::CommentPolicy::Scope).to receive(:resolve).and_return(comments_scope)
    end

    context 'unauthorized for remove_to_many_relationship' do
      before do
        disallow_operation(
          'remove_to_many_relationship',
          source_record: article,
          related_records: [comments_to_remove.first, comments_to_remove.second],
          relationship_type: :comments
        )
      end

      it { is_expected.to be_forbidden }
    end

    context 'authorized for remove_to_many_relationship' do
      context 'not limited by policy scopes' do
        before do
          allow_operation(
            'remove_to_many_relationship',
            source_record: article,
            related_records: [comments_to_remove.first, comments_to_remove.second],
            relationship_type: :comments
          )
        end

        it { is_expected.to be_successful }
      end

      context 'limited by policy scope on comments' do
        let(:comments_scope) { Comment.none }
        before do
          allow_operation('remove_to_many_relationship', source_record: article, related_records: [], relationship_type: :comments)
        end

        # This succeeds because the request isn't actually able to try removing any comments
        # due to the comments-to-be-removed being an empty array
        it { is_expected.to be_successful }
      end

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope on articles' do
        before do
          allow_operation(
            'remove_to_many_relationship',
            source_record: article,
            related_records: [comments_to_remove.first, comments_to_remove.second],
            relationship_type: :comments
          )
        end
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'DELETE api/v1/articles/:id/relationships/author' do
    subject(:last_response) { delete("api/v1/articles/#{article.external_id}/relationships/author") }

    let(:article) { articles(:article_with_author) }
    let(:policy_scope) { Article.all }

    context 'unauthorized for remove_to_one_relationship' do
      before { disallow_operation('remove_to_one_relationship', source_record: article, relationship_type: :author) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for remove_to_one_relationship' do
      before { allow_operation('remove_to_one_relationship', source_record: article, relationship_type: :author) }
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
