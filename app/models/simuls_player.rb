class SimulsPlayer < ApplicationRecord
  belongs_to :simul
  belongs_to :player

  after_commit :broadcast_score, on: :update
  after_commit :broadcast_result, on: :update

  after_commit  :regen_numbers, on: :destroy

  def name
    player.name
  end

  def swap_number other_player
    self.number, other_player.number = other_player.number, self.number
  end

  protected
  def regen_numbers
    SimulsPlayer.where('simul_id = ? AND number > ?', simul.id, self.number).update_all("number = number - 1")
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
