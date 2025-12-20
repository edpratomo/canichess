class ListedEvent < ActiveRecord::Base
  belongs_to :eventable, :polymorphic => true
  has_many :players
end
