class SimulsPlayer < ApplicationRecord
  belongs_to :simul
  belongs_to :player

  def name
    player.name
  end

  def swap_number other_player
    self.number, other_player.number = other_player.number, self.number
  end
end
