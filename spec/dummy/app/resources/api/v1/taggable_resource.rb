# http://jsonapi-resources.com/v0.9/guide/resources.html#Relationships
#
# > The polymorphic relationship will require the resource
# > and controller to exist, although routing to them will
# > cause an error.
module Api::V1
  class TaggableResource < JSONAPI::Resource
    def self.verify_key(key, _context = nil)
      # Allow a string key for polymorphic associations
      key && String(key)
    end
  end
end
