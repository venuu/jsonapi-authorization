class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments
end
