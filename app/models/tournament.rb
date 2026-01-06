class Tournament < ApplicationRecord
  include Eventable

  # polymorphic many-to-many:
  # tournaments <= events_sponsors => sponsors
  # simuls      <= events_sponsors => sponsors
  has_many :events_sponsors, :as => :eventable
  has_many :sponsors, :through => :events_sponsors, :as => :eventable

  # polymorphic
  has_many :event_subscriptions, as: :eventable

  has_many :boards
  has_many :standings

  # many-to-many players
  has_many :tournaments_players, dependent: :destroy
  has_many :players, through: :tournaments_players

  has_many :groups
  has_one_attached :logo
  
  after_create :create_default_group
  before_destroy :delete_listed_event

  def logo_url
    if logo.attached?
      logo
    else
     'logo-canichess-transparent.webp' 
    end
  end

  def logo_thumb
    logo.variant(resize_to_limit: [50, 50])
  end

  def get_results round=nil
    round ||= current_round
    boards.where(round: round).where.not(result: nil).map {|e|
      {id: e.id, result: e.result, walkover: e.walkover}
    }
  end

  def boards_per_round
    (players.size.to_f / 2).ceil
  end

  def percentage_completion
    return 100 if groups.all?(&:is_finished?)
    return 0 if boards.count == 0

    (groups.sum {|e| e.completed_round } * 100 / groups.sum {|e| e.rounds }).floor
  end
  
  def delete_player_label_at label_idx
    player_labels.delete_at(label_idx)
    save
  end

  def delete_group_boards group
    boards.where(group: group).destroy_all
  end

  def add_player args
    new_player = if args[:id] # existing player
      Player.find(args[:id])
    elsif args[:name]
      Player.create!(name: args[:name])
    end
    players << new_player
    if args[:group]
      new_player.tournaments_players.find_by(tournament: self).update!(group: args[:group])
    end
    new_player
  end

  def withdraw_wo_players
    tournaments_players.where('wo_count > ?', self.max_walkover).each do |t_player|
      t_player.update!(blacklisted: true)
    end
  end

  def all_boards_finished? round
    not boards.find_by(result: nil, round: round)
  end

  def any_board_finished? round
    boards.where(round:round).where.not(white: nil).where.not(black: nil).where.not(result: nil).size > 0
  end

  private

  def create_default_group
    Swiss.create!(tournament: self, name: 'Default', rounds: 7)
  end
end
