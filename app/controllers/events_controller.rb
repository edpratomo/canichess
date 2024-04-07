class EventsController < ApplicationController
  include ActionController::Live

  skip_before_action :authenticate_user!
  before_action :set_tournament
  before_action :set_round, only: %i[ pairings ]

  def pairings
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate
    sse = SSE.new(response.stream, event: "message")
    # long polling
    loop do
      data = @tournament.get_results(@round)
      unless data.empty?
        sse.write(JSON.pretty_generate(data))
      end
      sleep 1
    end
  rescue IOError
    logger.debug("Client disconnected")
  ensure
    sse.close
  end

  def simul
  end

  private
  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
  
  def set_round
    @round = params[:id].to_i
  end
end
