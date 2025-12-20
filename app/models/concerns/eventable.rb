module Eventable
  extend ActiveSupport::Concern

  included do
    has_one :listed_event, :as => :eventable
  end
end
