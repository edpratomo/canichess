module Eventable
  extend ActiveSupport::Concern

  included do
    has_one :listed_event, :as => :eventable

    after_create :create_listed_event, if: -> { listed }
    after_commit :create_listed_event, on: :update, if: -> { saved_change_to_listed? and listed and not listed_event}
    after_commit :delete_listed_event, on: :update, if: -> { saved_change_to_listed? and not listed }
  end

  private

  def create_listed_event
    ListedEvent.create(eventable: self)
  end

  def delete_listed_event
    ListedEvent.where(eventable: self).destroy_all
  end
end
