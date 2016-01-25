require 'spec_helper'

describe 'Test request', type: :request do
  fixtures :articles

  let(:authorizations) { {} }
  let(:policy_scope) { Article.none }

  before do
    authorizations.each do |action, retval|
      allow_any_instance_of(ArticlePolicy).to receive("#{action}?").and_return(retval)
    end
    allow_any_instance_of(ArticlePolicy::Scope).to receive(:resolve).and_return(policy_scope)
  end

  describe 'GET /articles' do
    context 'unauthorized for index?' do
      let(:authorizations) { {index: false} }

      it 'it is forbidden' do
        expect(get('/articles')).to be_forbidden
      end
    end

    context 'Authorized for index?' do
      let(:authorizations) { {index: true} }
      let(:policy_scope) { Article.where(id: Article.first.id) }

      it 'returns results limited by policy scope' do
        body = JSON.parse(get('/articles').body)
        expect(body["data"].length).to eq(1)
        expect(body["data"].first["id"]).to eq(Article.first.id.to_s)
      end

      it 'returns 200 OK' do
        expect(get('/articles')).to be_ok
      end
    end
  end

  describe 'GET /articles/:id' do
    context 'unauthorized for show?' do
      xit 'is forbidden'
    end

    context 'unauthorized for index?' do
      xit 'is forbidden'
    end

    context 'Authorized for show? and index?' do
      xit 'returns 200 OK'
    end
  end

  describe 'GET /articles/:id/relationships' do
    pending
  end

  describe 'GET /articles/:id/comments' do
    pending
  end

  describe 'GET /articles/:id/author' do
    pending
  end

  describe 'POST /articles' do
    context 'unauthorized for create?' do
      xit 'is forbidden'
    end

    context 'authorized for create?' do
      xit 'returns 201 Created'
    end
  end

  describe 'POST /articles/:id/relationships/comments' do
    context 'unauthorized for create?' do
      xit 'is forbidden'
    end

    context 'authorized for create?' do
      xit 'returns 201 Created'
    end
  end

  describe 'PATCH /articles/:id/relationships/author' do
    # TODO: Remember to check for null (removing association)

    context 'unauthorized for create?' do
      xit 'is forbidden'
    end

    context 'authorized for create?' do
      xit 'returns 201 Created'
    end
  end

  describe 'DELETE /articles/:id/relationships/comments' do
    pending
  end

  describe 'DELETE /articles/:id' do
    pending
  end
end
