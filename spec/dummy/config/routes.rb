Rails.application.routes.draw do
  jsonapi_resources :articles do
    jsonapi_relationships
  end
  jsonapi_resources :comments do
    jsonapi_relationships
  end
  jsonapi_resources :tags

  namespace :api do
    namespace :v1 do
      jsonapi_resources :articles do
        jsonapi_relationships
      end
      jsonapi_resources :comments do
        jsonapi_relationships
      end
      jsonapi_resources :tags
    end
  end
end
