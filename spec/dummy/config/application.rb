require File.expand_path('../boot', __FILE__)

require "rails/all"
Bundler.require(:default, Rails.env)

class Application < Rails::Application
  config.root = File.expand_path("../..", __FILE__)
  config.cache_classes = true

  config.eager_load = false
  config.serve_static_files = true
  config.static_cache_control = "public, max-age=3600"

  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  config.action_dispatch.show_exceptions = false

  config.action_controller.allow_forgery_protection = false

  config.active_support.deprecation = :stderr

  config.middleware.delete "Rack::Lock"
  config.middleware.delete "ActionDispatch::Flash"
  config.middleware.delete "ActionDispatch::BestStandardsSupport"

  config.secret_key_base = "correct-horse-battery-staple"
end

JSONAPI.configure do |config|
  config.default_processor_klass = JSONAPI::Authorization::AuthorizingOperationsProcessor
  config.exception_class_whitelist = [Pundit::NotAuthorizedError]
end
