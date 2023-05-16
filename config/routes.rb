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
        delete ':tournament_id/:round_id/delete' => 'boards#delete_by_round'
      end
    end
  end

  resources :boards

  get 'home/index'
  get 'home/:id/pairings' => 'home#pairings_by_round', as: "pairings"
  get 'home/:id/standings' => 'home#standings_by_round', as: "standings"
  get 'home/:id/player' => 'home#player', as: "player"
  get 'home/contact' => 'home#contact', as: "contact"
  
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

  get '/admin', to: redirect('/admin/tournaments')  
end
