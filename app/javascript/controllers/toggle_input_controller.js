import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "field"]

  connect() {
    // this.toggle()
    console.log("ToggleInputController connected")
  }

  toggle() {
    const selected = this.radioTargets.find(radio => radio.checked)
    const disable = selected && selected.value === "RoundRobin"

    this.fieldTargets.forEach(field => {
      field.disabled = disable
    })

    if (disable) {
      toastr.info("Round and Bipartite Matching inputs are irrelevant for Round Robin")
    } else {
      toastr.success("Round and Bipartite Matching inputs enabled")
    }
  }
}
