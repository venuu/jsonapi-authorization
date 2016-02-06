class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments, acts_as_set: true
  has_one :author, class_name: 'User'

  # # Hack for easy include directive checks
  has_many :articles
  has_one :article
end
