class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :trackable, #:registerable,
         :recoverable, :rememberable, :validatable

  include Gravtastic
  gravtastic default: "identicon"

end
