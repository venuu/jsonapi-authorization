# frozen_string_literal: true

class UsersController < ApplicationController
  include JSONAPI::ActsAsResourceController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def context
    { user: nil }
  end

  # https://github.com/cerebris/jsonapi-resources/pull/573
  def handle_exceptions(err)
    if JSONAPI.configuration.exception_class_whitelist.any? { |k| err.class.ancestors.include?(k) }
      raise err
    end

    super
  end

  def user_not_authorized
    head :forbidden
  end
end
