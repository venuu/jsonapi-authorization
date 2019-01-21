require 'spec_helper'

RSpec.describe JSONAPI::Authorization::DefaultPunditAuthorizer, pundit: "2.0" do
  it_behaves_like :default_pundit_authorizer, %i[api v1]
end
