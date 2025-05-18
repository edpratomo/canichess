class SimulScoreChannel < ApplicationCable::Channel
  def subscribed
    stream_from "simul_score"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
