import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="simul-result"
export default class extends Controller {
  connect() {
    console.log("SimulResult controller connected");
    this.subscription = consumer.subscriptions.create("SimulResultChannel", {
      received: data => {
        // Update DOM
        console.log("stimulus received simul result:", data);
        $('#player_' + data.id).html(this.resultText(data.result, data.color))
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  resultText(result, color) {
    if (!result) return '';

    let resultStr;
    if (result === color) {
      resultStr = '<div class="ribbon bg-success">WON</div>';
    } else if (result === "draw") {
      resultStr = '<div class="ribbon bg-warning">DRAW</div>';
    } else {
      resultStr = '<div class="ribbon bg-primary">LOST</div>';
    }

    return `
      <div class="ribbon-wrapper ribbon">
        ${resultStr}
      </div>
    `;
  }
}
