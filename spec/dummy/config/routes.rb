Rails.application.routes.draw do
  jsonapi_resources :articles do
    jsonapi_relationships
  end
  jsonapi_resources :comments do
    jsonapi_relationships
  end
  jsonapi_resources :tags

  namespace :nested_path do
    jsonapi_resources :articles do
      jsonapi_relationships
    end
    jsonapi_resources :comments do
      jsonapi_relationships
    end
    jsonapi_resources :tags
  end
end
