class ArticlesController < ActionController::Base
  include JSONAPI::ActsAsResourceController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def context
    {user: nil}
  end

  # https://github.com/cerebris/jsonapi-resources/pull/573
  def handle_exceptions(e)
    if JSONAPI.configuration.exception_class_whitelist.any? { |k| e.class.ancestors.include?(k) }
      raise e
    else
      super
    end
  end

  def user_not_authorized
    head :forbidden
  end
end
