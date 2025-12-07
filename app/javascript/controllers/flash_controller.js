import { Controller } from "@hotwired/stimulus"
import toastr from "toastr"

// Connects to data-controller="flash"
export default class extends Controller {
  static values = { message: String }

  connect() {
    let type = this.element.dataset.flashType;
    let message = this.element.dataset.flashMessage;

    console.log("flash_controller: " + type + " - " + message);
    console.log("toastr: " + toastr);
    //toastr[type](message);
  }

  show() {
    const message = this.element.dataset.flashMessage
    // Assuming you have toastr included
    if (typeof toastr !== 'undefined') {
      toastr.info(message)
    } else {
      alert(message)  // Fallback if toastr not available
    }
  }
}
