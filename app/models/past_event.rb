class PastEvent < ActiveRecord::Base
  belongs_to :eventable, :polymorphic => true
end
