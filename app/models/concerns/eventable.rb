module Eventable
  extend ActiveSupport::Concern

  included do
    has_one :past_event, :as => :eventable
  end
end
