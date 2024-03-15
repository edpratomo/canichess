$(document).on('turbolinks:load', function () {
  updateHiddenField = function () {
    console.log("foo called");
    $('select').each(function() {
      var select = $(this);
      var new_name = $(select).find(":selected").text();
      if ($(select).find(":selected").val() == "0") {
        $("#tournament_player_names").after("<input name='tournament[player_names][]' value='" + new_name +"' />");
        console.log("name: " + new_name);
      }
    });

    alert("ok");

  }
});
