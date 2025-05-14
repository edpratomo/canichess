class SimulResultChannel < ApplicationCable::Channel
  def subscribed
    stream_from "simul_result"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
