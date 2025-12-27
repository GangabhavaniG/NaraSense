Rails.application.routes.draw do
   # API Routes
  namespace :api do
    namespace :v1 do
      devise_for :users, controllers: {
        sessions: 'api/v1/sessions'
      }
    end
  end  
end
