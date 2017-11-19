Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      jsonapi_resources :schedules
      jsonapi_resources :scheduled_tracks
    end
  end

end
