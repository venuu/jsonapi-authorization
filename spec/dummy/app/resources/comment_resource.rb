class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_one :article
end
