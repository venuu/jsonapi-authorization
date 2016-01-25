class CommentResource < JSONAPI::Resource
  include JSONAPI::Authorization::ResourcePolicyAuthorization
end
