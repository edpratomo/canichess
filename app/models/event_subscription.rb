class EventSubscription < ApplicationRecord
  belongs_to :device_token
  belongs_to :eventable, polymorphic: true
end
