class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::ResourcePolicyAuthorization

  has_many :comments, acts_as_set: true
  has_one :author, class_name: 'User'
end
