require "rails_helper"

RSpec.describe Admin::SimulsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/admin/simuls").to route_to("admin/simuls#index")
    end

    it "routes to #new" do
      expect(get: "/admin/simuls/new").to route_to("admin/simuls#new")
    end

    it "routes to #show" do
      expect(get: "/admin/simuls/1").to route_to("admin/simuls#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/admin/simuls/1/edit").to route_to("admin/simuls#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/admin/simuls").to route_to("admin/simuls#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/admin/simuls/1").to route_to("admin/simuls#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/admin/simuls/1").to route_to("admin/simuls#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/admin/simuls/1").to route_to("admin/simuls#destroy", id: "1")
    end
  end
end
