class RoundFinishedChannel < ApplicationCable::Channel
  def subscribed
    stream_from "round_finished"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
