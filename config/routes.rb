Rails.application.routes.draw do
  get 'players/index'
  get 'players/show'
  get 'home/index'

  namespace :admin do
    resources :players
  end
  namespace :admin do
    resources :tournaments
  end

  namespace :admin do
    resources :tournaments_players
  end

  devise_for :users, skip: [:registrations]
  resources :users
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"
  
end
