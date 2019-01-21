require 'spec_helper'

RSpec.describe JSONAPI::Authorization::DefaultPunditAuthorizer do
  it_behaves_like :default_pundit_authorizer, []
end
