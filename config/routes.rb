Rails.application.routes.draw do
  resources :tournaments do
    collection do
      get ':id/:round_id/standings' => 'tournaments#standings_by_round', as: "standings"
      get ':id/:round_id/pairings' => 'tournaments#pairings_by_round', as: "pairings"
      get 'player/:player_id' => 'tournaments#player', as: "player"
    end
  end

  get 'events/:id/pairings' => 'events#pairings', as: "events_pairings"
  get 'events/simul'
  get 'simuls/:id/show' => 'simuls#show', as: "simul"
  get 'simuls/:id/result' => 'simuls#result', as: "simul_result"

  namespace :admin do
    resources :simuls
  end

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
        delete ':tournament_id/:round_id/delete' => 'boards#delete_by_round', as: "delete"
      end
    end
  end

  resources :boards

  get 'home/index'
  get 'home/contact' => 'home#contact', as: "contact"

  namespace :admin do
    resources :players do
      collection do
        get 'suggestions'
      end
    end
  end
  namespace :admin do
    resources :tournaments do
      collection do
        patch ':id/start' => 'tournaments#start', as: "start"
        patch ':id/update_players' => 'tournaments#update_players', as: "update_players"
      end
    end
  end

  namespace :admin do
    resources :tournaments_players do
      collection do
        get  ':id/list' => 'tournaments_players#index_by_tournament', as: "tournament"
        get  ':id/new' => 'tournaments_players#new', as: "new"

        get  ':id/upload' => 'tournaments_players#upload', as: "upload"
        post ':id/create_preview' => 'tournaments_players#create_preview', as: "create_preview"
        get  ':id/preview' => 'tournaments_players#preview', as: "preview"
      end
    end
  end

  devise_for :users #, skip: [:registrations]
  resources :users
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"

  get '/admin', to: redirect('/admin/tournaments')  
end
