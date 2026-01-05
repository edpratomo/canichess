class FcmNotificationJob < ApplicationJob
  queue_as :default

  def perform(tournament_id, title, body)
    Rails.logger.debug "FCM topic: tournament_#{tournament_id}"

    FcmService.new.send_to_topic(
      topic: "tournament_#{tournament_id}",
      title: title,
      body: body
    )
  end
end
