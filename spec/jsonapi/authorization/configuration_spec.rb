require 'spec_helper'
RSpec.describe JSONAPI::Authorization::Configuration do
  after do
    # Set this back to the default after each
    JSONAPI::Authorization.configuration.pundit_user = :user
  end

  describe '#user_context' do
    context "given a symbol" do
      it "returns the 'user'" do
        JSONAPI::Authorization.configuration.pundit_user = :current_user

        user = User.new
        jsonapi_context = { current_user: user }
        user_context = JSONAPI::Authorization.configuration.user_context(jsonapi_context)

        expect(user_context).to be user
      end
    end

    context "given a proc" do
      it "returns the 'user'" do
        JSONAPI::Authorization.configuration.pundit_user = ->(context) { context[:current_user] }

        user = User.new
        jsonapi_context = { current_user: user }
        user_context = JSONAPI::Authorization.configuration.user_context(jsonapi_context)

        expect(user_context).to be user
      end
    end
  end

  describe "#name_space" do
    context "given a array of symbol" do
      it "returns an array" do
        jsonapi_context = { name_space: %i[api v1] }
        name_space = JSONAPI::Authorization.configuration.name_space(jsonapi_context)

        expect(name_space).to be_instance_of(Array)
      end
    end
  end
end
