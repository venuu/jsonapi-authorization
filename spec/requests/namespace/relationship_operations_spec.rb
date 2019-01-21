require 'spec_helper'

RSpec.describe 'Relationship operations', type: :request, pundit: "2.0" do
  it_behaves_like :relationship_operations, "/api/v1"
end
