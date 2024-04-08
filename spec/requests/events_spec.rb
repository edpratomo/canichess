require 'rails_helper'

RSpec.describe "Events", type: :request do
  describe "GET /pairings" do
    it "returns http success" do
      get "/events/pairings"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /simul" do
    it "returns http success" do
      get "/events/simul"
      expect(response).to have_http_status(:success)
    end
  end

end
