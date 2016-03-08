class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments, acts_as_set: true
  has_many :tags
  has_one :author, class_name: 'User'

  primary_key :external_id

  def self.verify_key(key, _context = nil)
    key && String(key)
  end

  def id=(external_id)
    _model.external_id = external_id
  end

  # # Hack for easy include directive checks
  has_many :articles
  has_one :article
  has_one :non_existing_article, class_name: 'Article', foreign_key_on: :related
  has_many :empty_articles, class_name: 'Article', foreign_key_on: :related

  # Setting this attribute is an easy way to test that authorizations work even
  # when the model has validation errors
  attributes :blank_value
end
