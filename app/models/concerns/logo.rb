module Logo
  extend ActiveSupport::Concern

  included do
    has_one_attached :logo
  end

  def logo_url
    if logo.attached?
      logo
    else
     'logo-canichess-transparent.webp' 
    end
  end

  def logo_thumb
    logo.variant(resize_to_limit: [50, 50])
  end
end
