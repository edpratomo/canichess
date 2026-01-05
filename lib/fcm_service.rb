require "googleauth"
require "faraday"
require "json"

class FcmService
  FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

  def initialize
    @project_id = ENV.fetch("FIREBASE_PROJECT_ID")
    @credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(
        Rails.root.join("config/firebase_service_account.json")
      ),
      scope: FCM_SCOPE
    )
  end

  def send_to_topic(topic:, title:, body:, data: {})
    access_token = fetch_access_token

    payload = {
      message: {
        topic: topic,
        notification: {
          title: title,
          body: body
        },
        data: data.transform_values(&:to_s)
      }
    }

    Faraday.post(
      "https://fcm.googleapis.com/v1/projects/#{@project_id}/messages:send",
      payload.to_json,
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }
    )
  end

  def send_to_token(token:, title:, body:, data: {})
    access_token = fetch_access_token

    payload = {
      message: {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: data.transform_values(&:to_s)
      }
    }

    response = Faraday.post(
      "https://fcm.googleapis.com/v1/projects/#{@project_id}/messages:send",
      payload.to_json,
      {
        "Authorization" => "Bearer #{access_token}",
        "Content-Type" => "application/json"
      }
    )

    JSON.parse(response.body)
  end

  private

  def fetch_access_token
    @credentials.fetch_access_token!["access_token"]
  end
end
