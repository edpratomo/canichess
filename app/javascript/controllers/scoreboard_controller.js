import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

// Connects to data-controller="scoreboard"
export default class extends Controller {
  connect() {
    console.log("Scoreboard controller connected");
    this.subscription = consumer.subscriptions.create("ScoreBoardChannel", {
      received: data => {
        // Update DOM
        console.log("stimulus received data:", data);
        $('#res_' + data.id).html(this.resultText(data.result, data.walkover, data.points))
      }
    })
  }

  disconnect() {
    if (this.subscription) {
      consumer.subscriptions.remove(this.subscription)
    }
  }

  resultText(val, walkover, points) {
    const woBadge = walkover ? ' <span class="badge bg-danger">WO</span> ' : ''
    const [winPts, drawPts, byePts] = points.split('/')

    switch (val) {
      case "white":
        return `${winPts} - 0${woBadge}`
      case "black":
        return `${woBadge}0 - ${winPts}`
      case "draw":
        return `${drawPts} - ${drawPts}`
      case "noshow":
        return "0 - 0"
      default:
        return ''
    }
  }
}
