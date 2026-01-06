class FcmNotificationJob < ApplicationJob
  sidekiq_options retry: 3
  
  queue_as :default

  def perform(tournament_id, title, body, data)
    Rails.logger.debug "FCM topic: tournament_#{tournament_id}"

    FcmService.new.send_to_topic(
      topic: "tournament_#{tournament_id}",
      title: title,
      body: body,
      data: data
    )
  end
end
