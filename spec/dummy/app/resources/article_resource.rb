class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::ResourcePolicyAuthorization

  has_many :comments
  has_one :author, class_name: 'User'
end
