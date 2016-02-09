class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments, acts_as_set: true
  has_one :author, class_name: 'User'

  # # Hack for easy include directive checks
  has_many :articles
  has_one :article
  has_one :non_existing_article, class_name: 'Article', foreign_key_on: :related
  has_many :empty_articles, class_name: 'Article', foreign_key_on: :related

  # Setting this attribute is an easy way to test that authorizations work even
  # when the model has validation errors
  attributes :blank_value
end
