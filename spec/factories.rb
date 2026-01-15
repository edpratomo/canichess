FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
  end

  factory :player do
    sequence(:name) { |n| "Player #{n}" }
    rating { 1500 }
    rating_deviation { 350 }
    rating_volatility { 0.06 }
    affiliation { 'N/A' }
    games_played { 0 }
    rated_games_played { 0 }
    
    trait :student do
      affiliation { 'student' }
    end
    
    trait :alumni do
      affiliation { 'alumni' }
    end
    
    trait :invitee do
      affiliation { 'invitee' }
    end
    
    trait :staff do
      affiliation { 'staff' }
    end
    
    trait :alumni_relatives do
      affiliation { 'alumni_relatives' }
    end
    
    trait :with_fide do
      fide_id { rand(1000000..9999999).to_s }
    end
  end

  factory :title do
    association :player
    sequence(:title_name) { |n| ["FM", "IM", "GM", "WFM", "WIM", "WGM"].sample }
  end

  factory :tournament do
    sequence(:name) { |n| "Tournament #{n}" }
    location { "Test Location" }
    max_walkover { 2 }
    rated { false }
    player_labels { [] }
    
    trait :rated do
      rated { true }
    end
    
    trait :with_sponsors do
      after(:create) do |tournament|
        create_list(:sponsor, 2, tournaments: [tournament])
      end
    end
  end

  factory :group do
    association :tournament
    sequence(:name) { |n| "Group #{n}" }
    rounds { 7 }
    type { 'Swiss' }
    win_point { 1.0 }
    draw_point { 0.5 }
    bye_point { 1.0 }
    h2h_tb { false }
  end

  factory :swiss, parent: :group, class: 'Swiss' do
    type { 'Swiss' }
  end

  factory :round_robin, parent: :group, class: 'RoundRobin' do
    type { 'RoundRobin' }
  end

  factory :tournaments_player do
    association :tournament
    association :player
    association :group
    points { 0.0 }
    wo_count { 0 }
    blacklisted { false }
    start_rating { 1500 }
    end_rating { 1500 }
    labels { [] }
  end

  factory :board do
    association :tournament
    association :group
    round { 1 }
    sequence(:number) { |n| n }
    result { nil }
    walkover { false }
    
    trait :with_players do
      association :white, factory: :tournaments_player
      association :black, factory: :tournaments_player
    end
    
    trait :white_wins do
      result { 'white' }
    end
    
    trait :black_wins do
      result { 'black' }
    end
    
    trait :draw do
      result { 'draw' }
    end
    
    trait :bye do
      black { nil }
      result { 'white' }
    end
  end

  factory :standing do
    association :tournament
    association :tournaments_player
    round { 1 }
    points { 0.0 }
    median { 0.0 }
    solkoff { 0.0 }
    cumulative { 0.0 }
    opposition_cumulative { 0.0 }
    playing_black { 0 }
    blacklisted { false }
    sb { 0.0 }
    wins { 0 }
    h2h_rank { 0 }
  end

  factory :sponsor do
    sequence(:name) { |n| "Sponsor #{n}" }
    sequence(:url) { |n| "https://sponsor#{n}.example.com" }
    
    trait :with_tournaments do
      after(:create) do |sponsor|
        create_list(:tournament, 2, sponsors: [sponsor])
      end
    end
  end

  factory :events_sponsor do
    association :sponsor
    association :eventable, factory: :tournament
  end

  factory :simul do
    sequence(:name) { |n| "Simul #{n}" }
    location { "Test Location" }
    status { :not_started }
    playing_color { 'white' }
    alternate_color { 2 }
    
    trait :on_going do
      status { :on_going }
    end
    
    trait :completed do
      status { :completed }
    end
  end

  factory :simuls_player do
    association :simul
    association :player
    sequence(:number) { |n| n }
    color { 'black' }
    result { nil }
    
    trait :won do
      result { color }
    end
    
    trait :lost do
      result { color == 'white' ? 'black' : 'white' }
    end
    
    trait :draw do
      result { 'draw' }
    end
  end

  factory :merged_standings_config do
    sequence(:name) { |n| "Merged Standings Config #{n}" }
  end

  factory :merged_standing do
    association :merged_standings_config
    association :player
    points { 0.0 }
    median { 0.0 }
    solkoff { 0.0 }
    cumulative { 0.0 }
    opposition_cumulative { 0.0 }
    playing_black { 0 }
    blacklisted { false }
    sb { 0.0 }
    wins { 0 }
    h2h_cluster { 0 }
    h2h_points { 0.0 }
    labels { [] }
  end

  # Legacy factories for backward compatibility
  factory :admin_simul, class: 'Simul' do
    sequence(:name) { |n| "Admin Simul #{n}" }
    location { "Admin Location" }
    status { :not_started }
    playing_color { 'white' }
    alternate_color { 2 }
  end

  factory :admin_board, class: 'Board' do
    association :tournament
    association :group
    round { 1 }
  end
end
