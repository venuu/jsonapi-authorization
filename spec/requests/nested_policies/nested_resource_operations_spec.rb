require 'spec_helper'

describe 'Nested Resource operations', type: :request do
  include AuthorizationStubs
  fixtures :all

  let(:article) { Article.all.sample }
  let(:policy_scope) { Article.none }

  subject { last_response }
  let(:json_data) { JSON.parse(last_response.body)["data"] }

  before do
    allow_any_instance_of(NestedPath::ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  before do
    header 'Content-Type', 'application/vnd.api+json'
  end

  describe 'GET /nested_path/articles' do
    subject(:last_response) { get('nested_path/articles') }

    context 'unauthorized for find' do
      before { disallow_operation('find', source_class: Article, nested_path: [:nested_path]) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for find' do
      before { allow_operation('find', source_class: Article, nested_path: [:nested_path]) }
      let(:policy_scope) { Article.where(id: article.id) }

      it { is_expected.to be_ok }

      it 'returns results limited by policy scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(article.external_id)
      end
    end
  end

  describe 'GET /nested_path/articles/:id' do
    subject(:last_response) { get("nested_path/articles/#{article.external_id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show' do
      before { disallow_operation('show', source_record: article, nested_path: [:nested_path]) }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for show' do
      before { allow_operation('show', source_record: article, nested_path: [:nested_path]) }
      it { is_expected.to be_ok }

      # If this happens in real life, it's mostly a bug. We want to document the
      # behaviour in that case anyway, as it might be surprising.
      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'POST /nested_path/articles' do
    subject(:last_response) { post("nested_path/articles", json) }
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "id": "external_id",
          "type": "articles"
        }
      }
      EOS
    end

    context 'unauthorized for create_resource' do
      before { disallow_operation('create_resource', source_class: Article, nested_path: [:nested_path], related_records_with_context: []) }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create_resource' do
      before { allow_operation('create_resource', source_class: Article, nested_path: [:nested_path], related_records_with_context: []) }
      it { is_expected.to be_successful }
    end
  end

  describe 'PATCH /nested_path/articles/:id' do
    let(:json) do
      <<-EOS.strip_heredoc
      {
        "data": {
          "id": "#{article.external_id}",
          "type": "articles"
        }
      }
      EOS
    end

    subject(:last_response) { patch("nested_path/articles/#{article.external_id}", json) }
    let(:policy_scope) { Article.all }

    context 'authorized for replace_fields' do
      before { allow_operation('replace_fields', source_record: article, nested_path: [:nested_path], related_records_with_context: []) }
      it { is_expected.to be_successful }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'unauthorized for replace_fields' do
      before { disallow_operation('replace_fields', source_record: article, nested_path: [:nested_path], related_records_with_context: []) }
      it { is_expected.to be_forbidden }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'DELETE /nested_path/articles/:id' do
    subject(:last_response) { delete("/nested_path/articles/#{article.external_id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for remove_resource' do
      before { disallow_operation('remove_resource', source_record: article, nested_path: [:nested_path]) }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for remove_resource' do
      before { allow_operation('remove_resource', source_record: article, nested_path: [:nested_path]) }
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
