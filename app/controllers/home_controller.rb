class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'htab.html.erb'
  
  def index
  end
end
