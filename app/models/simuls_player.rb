class SimulsPlayer < ApplicationRecord
  belongs_to :simul
  belongs_to :player

  after_commit :broadcast_score, on: :update
  after_commit :broadcast_result, on: :update, if: :result_changed?

  after_commit :regen_numbers, on: :destroy

  def name
    player.name
  end

  def swap_number other_player
    curr_number = self.number
    transaction do
      self.update(number: other_player.number)
      other_player.update(number: curr_number)
    end
  end

  def update_number inc_or_dec_number
    transaction do
      if inc_or_dec_number == "increase"
        # find next player
        next_player = SimulsPlayer.find_by(simul: simul, number: self.number + 1)
        if next_player
          self.swap_number(next_player)
        end
      else
        # find prev player
        prev_player = SimulsPlayer.find_by(simul: simul, number: self.number - 1)
        if prev_player
          self.swap_number(prev_player)
        end
      end
    end
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
