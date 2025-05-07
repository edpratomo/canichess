class SimulsPlayer < ApplicationRecord
  belongs_to :simul
  belongs_to :player

  def name
    player.name
  end

end
