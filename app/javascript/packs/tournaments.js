$(document).on('turbolinks:load', function () {

  $('#tournament_players_file').on('change', (e) => {
    var fileName = e.target.files[0].name;
    $('#tournament_players_file_label').html(fileName);
  });

});
