// app/javascript/controllers/escape_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["exitFullscreen"]

  connect() {
    console.log("EscapeController connected")
    this.keydownHandler = this.handleKeydown.bind(this)
    window.addEventListener("keydown", this.keydownHandler)
  }

  disconnect() {
    window.removeEventListener("keydown", this.keydownHandler)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      console.log("Escape key pressed!")
      const pathOnly = window.location.pathname.split("?")[0];
      window.location.href = pathOnly;
    }
  }
}
