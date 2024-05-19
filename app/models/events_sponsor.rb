class EventsSponsor < ActiveRecord::Base
  # polymorphic many-to-many:
  # tournaments <= events_sponsors => sponsors
  # simuls      <= events_sponsors => sponsors
  belongs_to :sponsor
  belongs_to :eventable, :polymorphic => true
end
