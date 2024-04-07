class EventsController < ApplicationController
  include ActionController::Live

  skip_before_action :authenticate_user!
  before_action :set_tournament
  before_action :set_round, only: %i[ pairings ]

  # Rack hijacking API (partial)
  def pairings
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["rack.hijack"] = proc do |stream|
      Thread.new do
        perform_task(stream)
      end
    end

    head :ok
  end

  def simul
  end

  private
  def perform_task(stream)
    sse = ActionController::Live::SSE.new(stream, retry: 300, event: "message")

    # long polling
    loop do
      data = @tournament.get_results(@round)
      unless data.empty?
        sse.write(JSON.pretty_generate(data))
      end
      sleep 3
    end
  rescue Errno::EPIPE
    logger.debug("Client disconnected")
  ensure
    sse.close
  end

  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
  
  def set_round
    @round = params[:id].to_i
  end
end
