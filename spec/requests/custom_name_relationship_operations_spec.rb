require 'spec_helper'

RSpec.describe 'including custom name relationships', type: :request do
  it_behaves_like :custom_name_relationship_operations
end
