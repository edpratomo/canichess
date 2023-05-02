class HomeController < ApplicationController
  skip_before_action :authenticate_user!
  layout 'plain.html.erb'
  
  def index
  end
end
