require 'spec_helper'

RSpec.describe 'including resources alongside normal operations', type: :request do
  it_behaves_like :included_resources
end
