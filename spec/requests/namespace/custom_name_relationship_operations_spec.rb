require 'spec_helper'

RSpec.describe 'including custom name relationships', type: :request, pundit: "2.0" do
  it_behaves_like :custom_name_relationship_operations, "/api/v1"
end
