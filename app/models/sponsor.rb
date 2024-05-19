class Sponsor < ActiveRecord::Base
  has_many :events_sponsors
  has_many :eventables, :through => :events_sponsor
end
