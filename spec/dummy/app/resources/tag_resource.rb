class TagResource < JSONAPI::Resource
  include JSONAPI::Authorization::PunditScopedResource

  has_one :taggable, polymorphic: true
end
