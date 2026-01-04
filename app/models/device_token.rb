class DeviceToken < ApplicationRecord
  validates :fcm_token, presence: true, uniqueness: true
end
