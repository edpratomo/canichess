class Sponsor < ActiveRecord::Base
  has_many :events_sponsors
  has_many :eventables, :through => :events_sponsor

  has_one_attached :logo do |attachable|
    attachable.variant :thumb, resize_to_limit: [180, 100] # , preprocessed: true
  end

  def logo_url
    if logo.attached?
      logo
    else
     'canichess-alumni-slide.webp' 
    end
  end

  def logo_thumb
    logo.variant(resize_to_limit: [180, 100])
  end
end
