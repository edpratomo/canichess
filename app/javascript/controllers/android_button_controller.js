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

    window.onTournamentSubscriptionChanged = (tournamentId, subscribed) => {
      if (tournamentId === this.tournamentIdValue) {
        this.updateLabel(subscribed)
      }
    }

    this.updateLabel(Android.isSubscribedToTournament(this.tournamentIdValue))
  }

  toggle() {
    if (Android.isSubscribedToTournament(this.tournamentIdValue)) {
      Android.unsubscribeFromTournament(this.tournamentIdValue)
    } else {
      Android.subscribeToTournament(this.tournamentIdValue)
    }
  }

  updateLabel(is_subscribed) {
    this.element.textContent = is_subscribed // this.subscribedValue
      ? "Stop Notifications"
      : "Notify Me for Updates"
  }
}
