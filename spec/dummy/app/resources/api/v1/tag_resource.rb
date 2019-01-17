# frozen_string_literal: true

module Api::V1
  class TagResource < JSONAPI::Resource
    include JSONAPI::Authorization::PunditScopedResource

    has_one :taggable, polymorphic: true
  end
end
