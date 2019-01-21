require 'spec_helper'

RSpec.describe 'including resources alongside normal operations', type: :request, pundit: "2.0" do
  it_behaves_like :included_resources, "/api/v1"
end
