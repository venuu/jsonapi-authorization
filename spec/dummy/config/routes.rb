Rails.application.routes.draw do
  jsonapi_resources :articles do
    jsonapi_relationships
  end
end
