class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  before_action :set_tournament

  layout 'top-nav.html.erb'
  
  def index
    redirect_to tournament_path(@tournament)
  end

  def contact
  end

  private
  def set_tournament
    @tournament = Tournament.find_by(fp: true)
  end
end
