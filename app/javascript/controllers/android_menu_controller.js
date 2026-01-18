import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="android-menu"
export default class extends Controller {
  static targets = [ "menuData" ]

  connect() {
    console.log("AndroidMenuController connected")
    this.setMenu()
  }

  setMenu() {
    window.AndroidMenu?.setMenu?.(this.menuDataTarget.textContent)
  }
}
