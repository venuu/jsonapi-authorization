# frozen_string_literal: true

require "jsonapi-resources"
require "jsonapi/authorization/authorizing_processor"
require "jsonapi/authorization/configuration"
require "jsonapi/authorization/default_pundit_authorizer"
require "jsonapi/authorization/pundit_scoped_resource"
require "jsonapi/authorization/version"

module JSONAPI
  module Authorization
    # Your code goes here...
  end
end

# Allows JSONAPI configuration of operations_processor using the symbol :jsonapi_authorization
JsonapiAuthorizationProcessor = JSONAPI::Authorization::AuthorizingProcessor
