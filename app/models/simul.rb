class Simul < ApplicationRecord
  include Eventable

  # polymorphic many-to-many:
  # tournaments <= events_sponsors => sponsors
  # simuls      <= events_sponsors => sponsors
  has_many :events_sponsors, :as => :eventable
  has_many :sponsors, :through => :events_sponsors, :as => :eventable

  has_many :simuls_players, dependent: :destroy
  has_many :players, through: :simuls_players

  has_one_attached :logo

  after_commit :assign_colors, on: :update, if: :playing_color_changed?

  enum status: [ :not_started, :on_going, :completed ]

  def assign_colors
    unless self.playing_color == 'alternate_color'
      simuls_players.update_all(color: self.playing_color)
      return
    end
    curr_color = 'black'
    simuls_players.order(:number).each do |player|
      player.update(color: curr_color)
      if player.number % self.alternate_color == 0
        if curr_color == 'black'
          curr_color = 'white'
        else
          curr_color = 'black'
        end
      end
    end
  end

  def logo_url
    if logo.attached?
      logo
    else
     'logo-canichess-transparent.webp' 
    end
  end

  def percentage_completion
    if players.count == 0
      0
    else
      ((simuls_players.where.not(result: nil).count.to_f / players.count) * 100).floor
    end
  end

  def add_player args
    if args[:id] # existing player
      transaction do
        players << Player.find(args[:id])
        this_player = simuls_players.last
        this_player.update(number: args[:number]) if args[:number]
      end
    elsif args[:name]
      transaction do
        players << Player.create!(name: args[:name])
        this_player = simuls_players.last
        this_player.update(number: args[:number]) if args[:number]
      end
    end
  end

  def score
    total_participants_score = simuls_players.where("result = color").count +
                               simuls_players.where("result = 'draw'").count * 0.5
    total_completed = simuls_players.where("result IS NOT NULL").count
    "#{total_completed - total_participants_score} - #{total_participants_score}"
  end

end
