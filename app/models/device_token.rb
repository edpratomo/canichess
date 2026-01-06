class DeviceToken < ApplicationRecord
  validates :fcm_token, presence: true, uniqueness: true

  has_many :event_subscriptions
end
