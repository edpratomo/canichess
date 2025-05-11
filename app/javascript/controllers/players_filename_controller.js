import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="players-filename"
export default class extends Controller {
  connect() {
    console.log("Players Filename controller connected!");
  }

  updateFilename(event) {
    const file = event.target.files[0];
    if (file) {
      const fileName = file.name;
      $('#simul_players_file_label').html(fileName);
    }    
  }
}
