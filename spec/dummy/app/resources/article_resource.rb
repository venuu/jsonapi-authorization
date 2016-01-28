class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments, acts_as_set: true
  has_one :author, class_name: 'User'
end
