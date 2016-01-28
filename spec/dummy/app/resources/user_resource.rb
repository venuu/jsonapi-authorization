class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource
end
