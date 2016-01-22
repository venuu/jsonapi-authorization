require 'spec_helper'

describe 'Test request', type: :request do
  it 'returns OK' do
    response = get '/'
    expect(response).to be_ok
  end
end
