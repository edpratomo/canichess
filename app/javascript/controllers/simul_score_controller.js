import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="simul-score"
export default class extends Controller {
  connect() {
    console.log("SimulScore controller connected");
    this.subscription = consumer.subscriptions.create("SimulScoreChannel", {
      received: data => {
        // Update DOM
        console.log("stimulus received simul score:", data);
        $('#simul_score').html(data.replace(/\.0/g, '').replace(/\b0\.5/g, '½').replace(/\.5/g, '½'))
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }
}
