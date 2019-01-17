# http://jsonapi-resources.com/v0.9/guide/resources.html#Relationships
#
# > The polymorphic relationship will require the resource
# > and controller to exist, although routing to them will
# > cause an error.
module Api::V1
  class TaggablesController < JSONAPI::ResourceController; end
end