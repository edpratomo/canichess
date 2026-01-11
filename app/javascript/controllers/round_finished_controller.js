import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="round-finished"
export default class extends Controller {
  static targets = ["bsAlert", "message"]
  static values = { groupId: Number }

  connect() {
    console.log("RoundFinishedController connected")
    const current_group_id = this.groupIdValue
    const thisElement = this.bsAlertTarget
    const thisElementMessage = this.messageTarget

    consumer.subscriptions.create("RoundFinishedChannel", {

      received(data) {
        // Called when there's incoming data on the websocket for this channel
        console.log("stimulus received round_finished:", data);
        console.log("current group_id: ", current_group_id);

        if (data.group_id == current_group_id) {
          if (data.completed) {
            thisElementMessage.innerHTML = 'Last round has finished. <a href="' + 
              data.url + '" class="alert-link">Final standings are available</a>'
          } else {
            thisElementMessage.innerHTML = 'Pairings for <a href="' + 
              data.url + '" class="alert-link">the next round are ready.'
          }
          thisElement.style.display = ""
        }
      }
    });
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }
}
