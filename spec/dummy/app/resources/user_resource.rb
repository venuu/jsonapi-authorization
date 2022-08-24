# frozen_string_literal: true

class UserResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_many :comments
end
