import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    tournamentId: Number,
    subscribed: Boolean
  }

  connect() {
    console.log("AndroidButtonController connected")
    if (!(window.Android && Android.subscribeToTournament)) {
      this.element.remove()
      return
    }

    this.updateLabel()
  }

  toggle() {
    if (this.subscribedValue) {
      Android.unsubscribeFromTournament(this.tournamentIdValue)
      this.subscribedValue = false
    } else {
      Android.subscribeToTournament(this.tournamentIdValue)
      this.subscribedValue = true
    }

    this.updateLabel()
  }

  updateLabel() {
    this.element.textContent = this.subscribedValue
      ? "Stop Notifications"
      : "Notify Me for Updates"
  }
}
