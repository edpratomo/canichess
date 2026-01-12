Rails.application.routes.draw do
  namespace :admin do
    resources :sponsors
  end
  mount ActionCable.server => '/cable'

  namespace :admin do
    resources :simuls do
      collection do
        patch ':id/start' => 'simuls#start', as: "start"
        patch ':id/update_players' => 'simuls#update_players', as: "update_players"
        patch ':id/update_colors' => 'simuls#update_colors', as: "update_colors"
      end
    end
  end

  namespace :admin do
    resources :simuls_players  do
      collection do
        get  ':id/result' => 'simuls_players#result', as: "result"
        patch ':id/update_result' => 'simuls_players#update_result', as: "update_result"
     
        get  ':id/list' => 'simuls_players#index_by_simul', as: "simul"
        get  ':id/new' => 'simuls_players#new', as: "new"

        get  ':id/upload' => 'simuls_players#upload', as: "upload"
        post ':id/create_preview' => 'simuls_players#create_preview', as: "create_preview"
        get  ':id/preview' => 'simuls_players#preview', as: "preview"
      end
    end
  end

  resources :tournaments do
    collection do
      get ':id/:group_id/standings' => 'tournaments#merged_standings', as: "merged_standings"
      #get ':id/:round_id/pairings' => 'tournaments#pairings_by_round', as: "pairings"
      get ':id/:group_id/:round_id/standings' => 'tournaments#standings_by_group', as: "group_standings"
      get ':id/:group_id/:round_id/pairings' => 'tournaments#pairings_by_group', as: "group_pairings"
      get ':id/:group_id/show' => 'tournaments#group_show', as: "group_show"
      get 'player/:player_id' => 'tournaments#player', as: "player"
      get ':id/players' => 'tournaments#players', as: "players"
      get ':id/:group_id/players' => 'tournaments#players_in_group', as: "group_players"
      get ':id/groups' => 'tournaments#groups', as: "groups"
    end
  end

  #get 'events/:id/pairings' => 'events#pairings', as: "events_pairings"
  get 'events/:group_id/:round_id/pairings' => 'events#pairings', as: "events_pairings"
  get 'events/simul'
  get 'simuls/:id/show' => 'simuls#show', as: "simul"
  get 'simuls/:id/result' => 'simuls#result', as: "simul_result"

  namespace :admin do
    resources :standings do
      collection do
        get ':tournament_id/:round_id/show' => 'standings#index_by_round', as: "round"
        get ':tournament_id/:group_id/:round_id/show' => 'standings#index_by_group', as: "group"
      end
    end
  end

  namespace :admin do
    resources :boards do
      collection do
        get ':tournament_id/:round_id/show' => 'boards#index_by_round', as: "round"
        delete ':tournament_id/:group_id/:round_id/delete' => 'boards#delete_by_round', as: "delete"
        #delete ':tournament_id/:group_id/delete_by_group' => 'boards#delete_by_group', as: "delete_group"
        get ':tournament_id/:group_id/:round_id/show' => 'boards#index_by_group', as: "group"
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
        patch ':id/:group_id/start' => 'tournaments#start', as: "start_group"
        patch ':id/update_players' => 'tournaments#update_players', as: "update_players"
        # get ':group_id/groups/edit' => 'tournaments#edit_group', as: "edit_group"
        # patch ':group_id/groups/update' => 'tournaments#update_group', as: "update_group"

        get ':id/:group_id/show' => 'tournaments#group_show', as: "group_show"
        patch ':id/:group_id/:round_id/finalize' => 'tournaments#finalize_round', as: "finalize"

        get ':id/edit_player_labels' => 'tournaments#edit_player_labels', as: "edit_player_labels"
        delete ':id/:label_idx/delete_player_label' => 'tournaments#delete_player_label', as: "delete_player_label"

        patch ':id/:group_id/:round_id/slow' => 'tournaments#slow_process', as: "slow"
      end

      resources :sponsors
      resources :groups
    end
  end

  namespace :admin do
    resources :tournaments_players do
      collection do
        get  ':id/:group_id/list' => 'tournaments_players#index_by_group', as: "group"
        get  ':id/list' => 'tournaments_players#index_by_tournament', as: "tournament"
        get  ':id/new' => 'tournaments_players#new', as: "new"

        get  ':id/upload' => 'tournaments_players#upload', as: "upload"
        post ':id/create_preview' => 'tournaments_players#create_preview', as: "create_preview"
        get  ':id/preview' => 'tournaments_players#preview', as: "preview"

        get  ':id/attach_label' => 'tournaments_players#attach_label', as: "attach_label"
        patch ':id/update_labels' => 'tournaments_players#update_labels', as: "update_labels"
        delete ':id/:label_idx/detach_label' => 'tournaments_players#detach_label', as: "detach_label"
      end
    end
  end

  devise_for :users, skip: [:registrations]
  
  as :user do
    get 'users/edit' => 'devise/registrations#edit', :as => 'edit_user_registration'
    # we have custom registrations#update in a subclass of Devise::Registrations
    put 'users' => 'users/registrations#update', :as => 'user_registration'
    # You can also add the patch and delete routes if needed
    patch 'users' => 'users/registrations#update', :as => 'update_user_registration'
    delete 'users' => 'devise/registrations#destroy', :as => 'destroy_user_registration'
  end

  #  resources :users, only: [:index, :show]
  namespace :admin do
    resources :users, only: [:new, :create, :index, :edit, :update, :show]
  end

# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: "home#index"

  get '/admin', to: redirect('/admin/tournaments')  
end
