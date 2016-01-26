require 'spec_helper'

describe 'Resource operations', type: :request do
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

  describe 'GET /articles' do
    before { get('/articles') }

    context 'unauthorized for index?' do
      let(:authorizations) { {index: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for index?' do
      let(:authorizations) { {index: true} }
      let(:policy_scope) { Article.where(id: article.id) }

      it { is_expected.to be_ok }

      it 'returns results limited by policy scope' do
        expect(json_data.length).to eq(1)
        expect(json_data.first["id"]).to eq(article.id.to_s)
      end
    end
  end

  describe 'GET /articles/:id' do
    before { get("/articles/#{article.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for show?' do
      let(:authorizations) { {show: false} }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
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
    end
  end

  describe 'POST /articles' do
    before { post("/articles", '{ "data": { "type": "articles" } }') }

    context 'unauthorized for create?' do
      let(:authorizations) { {create: false} }
      it { is_expected.to be_forbidden }
    end

    context 'authorized for create?' do
      let(:authorizations) { {create: true} }
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

    before { patch("/articles/#{article.id}", json) }
    let(:policy_scope) { Article.all }

    context 'authorized for update? on article' do
      let(:authorizations) { {update: true} }
      it { is_expected.to be_successful }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'unauthorized for update? on article' do
      let(:authorizations) { {update: false} }
      it { is_expected.to be_forbidden }

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end
  end

  describe 'DELETE /articles/:id' do
    before { delete("/articles/#{article.id}") }
    let(:policy_scope) { Article.all }

    context 'unauthorized for destroy?' do
      let(:authorizations) { {destroy: false} }

      context 'not limited by policy scope' do
        it { is_expected.to be_forbidden }
      end

      context 'limited by policy scope' do
        let(:policy_scope) { Article.where.not(id: article.id) }
        it { is_expected.to be_not_found }
      end
    end

    context 'authorized for destroy?' do
      let(:authorizations) { {destroy: true} }
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
