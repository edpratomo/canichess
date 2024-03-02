class PlayersList
  def initialize
    @players = []
  end

  def add new_player
    @players.push new_player
  end

  def update_exclusion
  
  end
  
  def get
    @players
  end
end
