Rails.application.routes.draw do
  namespace :admin do
    resources :standings do
      collection do
        get ':tournament_id/:round_id/show' => 'standings#index_by_round', as: "round"
      end
    end
  end

  namespace :admin do
    resources :boards do
      collection do
        get ':tournament_id/:round_id/show' => 'boards#index_by_round', as: "round"
      end
    end
  end

  resources :boards
  get 'players/index'
  get 'players/show'
  get 'home/index'

  namespace :admin do
    resources :players
  end
  namespace :admin do
    resources :tournaments do
      collection do
        patch ':id/start' => 'tournaments#start', as: "start"
      end
    end
  end

  namespace :admin do
    resources :tournaments_players do
      collection do
        get ':id/list' => 'tournaments_players#index_by_tournament', as: "tournament"
      end
    end
  end

  devise_for :users, skip: [:registrations]
  resources :users
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"
  
end
