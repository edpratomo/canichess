import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="fullscreen"
export default class extends Controller {
  connect() {
    console.log("Fullscreen controller connected");
    this.element.addEventListener('click', this.openFullscreen.bind(this));
  }

  disconnect() {
    console.log("Fullscreen controller disconnected");
    this.element.removeEventListener('click', this.openFullscreen.bind(this));
  }

  openFullscreen() {
    const pathOnly = window.location.pathname.split("?")[0];
    window.location.href = pathOnly + "?full=1";
  }
}
