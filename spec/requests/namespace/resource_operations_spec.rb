require 'spec_helper'

describe 'Resource operations', type: :request, pundit: "2.0" do
  it_behaves_like :resource_operations, "/api/v1"
end
