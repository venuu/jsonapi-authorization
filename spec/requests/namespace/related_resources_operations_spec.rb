require 'spec_helper'

RSpec.describe 'Related resources operations', type: :request, pundit: "2.0" do
  it_behaves_like :related_resources_operations, "/api/v1"
end
