class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::ResourcePolicyAuthorization
end
