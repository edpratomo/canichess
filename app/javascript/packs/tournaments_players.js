$(document).on('turbolinks:load', function () {
  var container = $("#hidden-fields-container");
  container.empty();

  updateHiddenField = function () {
    console.log("foo called");
    $('select').each(function() {
      var select = $(this);
      var new_name = $(select).find(":selected").text();
      if ($(select).find(":selected").val() == "0") {
        container.append("<input type='hidden' name='tournament[player_names][]' value='" + new_name +"' />");
        console.log("name: " + new_name);
      }
    });
  }
});
