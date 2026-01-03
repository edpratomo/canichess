// app/javascript/controllers/other_field_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "otherField" ]

  connect() {
    console.log("otherField controller connected")
    this.toggle() // Run on page load to set initial state
  }

  toggle() {
    // Check if the "other" radio button is the one currently checked
    const theRadioButton = this.element.querySelector('input[value="alternate_color"]:checked')
    
    if (theRadioButton) {
      console.log("otherField checked")
      this.showOtherField()
    } else {
      this.hideOtherField()
    }
  }

  showOtherField() {
    //this.otherFieldTarget.style.display = 'block'
    this.otherFieldTarget.querySelector('input[type="number"]').required = true
    this.otherFieldTarget.querySelector('input[type="number"]').disabled = false
  }

  hideOtherField() {
    //this.otherFieldTarget.style.display = 'none'
    this.otherFieldTarget.querySelector('input[type="number"]').required = false
    this.otherFieldTarget.querySelector('input[type="number"]').disabled = true
    this.otherFieldTarget.querySelector('input[type="number"]').value = '' // Optional: clear value when hidden
  }
}
