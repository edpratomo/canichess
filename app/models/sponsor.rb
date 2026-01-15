class Sponsor < ActiveRecord::Base
  has_many :events_sponsors
  has_many :tournaments, through: :events_sponsors, source: :eventable, source_type: 'Tournament'
  has_many :simuls, through: :events_sponsors, source: :eventable, source_type: 'Simul'

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

  def eventables
    #Tournament.joins(:events_sponsors).where(events_sponsors: {sponsor_id: id}).or(
    #  Simul.joins(:events_sponsors).where(events_sponsors: {sponsor_id: id})
    #)
    tournaments + simuls
  end
end
