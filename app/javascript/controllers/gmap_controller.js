// app/javascript/controllers/gmap_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = { src: String }

  connect() {
    console.log("GmapController connected")
    this.load()
  }

  load() {
    if (this.containerTarget.querySelector("iframe")) return
    const iframe = document.createElement("iframe")

    iframe.src = this.srcValue
    // doesn't work with display:none :
    //iframe.loading = "lazy"
    iframe.referrerPolicy = "no-referrer-when-downgrade"

    iframe.addEventListener("load", () => {
      this.containerTarget.classList.remove("hidden")
    })

    this.containerTarget.appendChild(iframe)
  }
}
