class ScoreBoardChannel < ApplicationCable::Channel
  def subscribed
    stream_from "score_board"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
