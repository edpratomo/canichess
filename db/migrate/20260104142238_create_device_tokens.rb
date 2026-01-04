class CreateDeviceTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :device_tokens do |t|
      t.string :fcm_token
      t.string :platform

      t.timestamps
    end
  end
end
