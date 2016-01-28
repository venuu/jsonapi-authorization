class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
end
