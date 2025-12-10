class Player < ApplicationRecord
  has_one :title
  has_many :tournaments_players
  has_many :tournaments, through: :tournaments_players
  has_many :simuls_players
  belongs_to :ccm_awarded_at, class_name: 'PastEvent', optional: true
  
  alias_attribute :volatility, :rating_volatility
  
  validates :rating, numericality: {only_integer: true}

  def canisian?
    self.affiliation == 'student' || self.affiliation == 'alumni'
  end

  def tournament_points(tournament)
    tourney_player = tournaments_players.find_by(tournament: tournament)
    tourney_player.points if tourney_player
  end

  def self.update_fide
    fide_api = 'https://fide-api.vercel.app/player_info/'
    fide_players = where.not(fide_id: nil).order(:id).reject {|e| e.fide_id.empty?}.map {|e| [e.id, e.fide_id]}

    # curl -s -X GET 'https://fide-api.vercel.app/player_info/?fide_id=7102909&history=false' -H 'accept: application/json' | jq .
    fide_players.each do |player_id, player_fide_id|
      rest_url = fide_api + "?fide_id=#{player_fide_id}&history=true"
      output = %x[curl -s -X GET -H 'accept: application/json' '#{rest_url}']
      if output
        begin
          tmp_obj = JSON.parse(output)
          update(player_id, fide_data: JSON.pretty_generate(tmp_obj))
        rescue JSON::ParserError
          puts "Failed to parse #{output}"
        end
      end
      sleep 5
    end
  end

  # list of joined events before the given event
  def history event
    PastEvent.includes(:eventable).where('created_at < ?', event.created_at).
      order(created_at: :asc).map {|e| e.eventable }.
      select {|e| e.players.any? {|ply| ply == self } }
  end
end
