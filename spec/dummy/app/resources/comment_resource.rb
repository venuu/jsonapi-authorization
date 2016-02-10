class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :tags
  has_one :article
end
