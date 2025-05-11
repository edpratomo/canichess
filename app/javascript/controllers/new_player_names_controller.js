import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="new-player-names"
export default class extends Controller {
  static targets = ["hiddenPlayerNames"]

  connect() {
    console.log("New Player Names controller connected!");
  }

  updatePlayerNames() {
    var element = $(this.hiddenPlayerNamesTarget);

    $('select').each(function() {
      var select = $(this);
      var new_name = $(select).find(":selected").text();
      if ($(select).find(":selected").val() == "0") {
        element.after("<input type='hidden' name='simul[player_names][]' value='" + new_name +"' />");
        console.log("name: " + new_name);
      }
    });
  }
}
