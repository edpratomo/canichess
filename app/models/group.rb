class Group < ApplicationRecord
  has_many :boards
  belongs_to :tournament, optional: true
end
