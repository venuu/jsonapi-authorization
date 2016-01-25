class ArticleResource < JSONAPI::Resource
  include JSONAPI::Authorization::ResourcePolicyAuthorization
end
