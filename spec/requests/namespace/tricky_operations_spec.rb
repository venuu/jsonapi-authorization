require 'spec_helper'

RSpec.describe 'Tricky operations', type: :request, pundit: "2.0" do
  it_behaves_like :tricky_operations, "/api/v1"
end
