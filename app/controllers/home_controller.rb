class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_front_page

  layout 'top-nav.html.erb'

  def index
    if @front_page
      if @front_page.is_a? Tournament
        redirect_to tournament_path(@front_page)
      elsif @front_page.is_a? Simul
        redirect_to simul_path(@front_page)
      end
    end
  end

  def contact
  end

  private
  def set_front_page
    front_page = ListedEvent.includes(:eventable).find {|e| e.eventable.fp }
    if front_page
      @front_page = front_page.eventable
    end
  end

  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
end
