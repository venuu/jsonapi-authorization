module NestedPath
  class CommentResource < JSONAPI::Resource
    include JSONAPI::Authorization::PunditScopedResource

    has_many :tags
    has_one :article
    has_one :reviewer, relation_name: "reviewing_user", class_name: "User"
  end
end
