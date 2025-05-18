class SimulsPlayer < ApplicationRecord
  belongs_to :simul
  belongs_to :player

  after_commit :broadcast_score, on: :update
  after_commit :broadcast_result, on: :update

  def name
    player.name
  end

  def swap_number other_player
    self.number, other_player.number = other_player.number, self.number
  end

  private
  def broadcast_score
    ActionCable.server.broadcast "simul_score", simul.score
  end

  def broadcast_result
    ActionCable.server.broadcast "simul_result", {
      id: id,
      result: result,
      color: color
    }
  end
end
