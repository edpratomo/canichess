$(document).on('turbolinks:load', function () {
  console.log("turbolinks:load TRIGGERED simuls_players.js");
  var last_simul_radio_state = [];

  getSimulRadioByValue = function(radios, value) {
    for (var i = 0; i < radios.length; i++) {       
      if (radios[i].value == value) {
        return radios[i];
      }
    }
  }

  getCheckedSimulRadio = function(radios) {
    for (var i = 0; i < radios.length; i++) {       
      if (radios[i].checked) {
        return radios[i];
      }
    }
  }

  updateSimulRadio = function(element) {
    var form_action = element.form.action;
    var form_id = element.form.id;
    var found_form = document.querySelector("#" + form_id);
    var radios = found_form.elements[element.name];
    var last_state = last_simul_radio_state[form_id];

    var form_ary = form_id.split("_");
    var td_player_id = "#td_player_" + form_ary.slice(-1);

    console.log("[update_SimulRadio] form_action: " + form_action);

    $.ajax({
      url: form_action + '.json',
      type: 'PATCH',
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      data: { _method:'patch', simuls_player: { result: element.value } },
      dataType: 'json',
      'error' : function(response) {
          console.log("response: " + response.status);
          console.log("reverting to: " + last_state);
          // revert the change
          if (last_state) {
            var found_radio = getSimulRadioByValue(radios, last_state);
            found_radio.checked = true;
          } else {
            element.checked = false;
          }
      },
      'success': function(data) {
        $(td_player_id).removeClass("bg-warning");
      },
    });
  }

  checkSimulRadio = function(element) {
    var form_id = element.form.id;
    var found_form = document.querySelector("#" + form_id);
    
    // RadioNodeList
    var radios = found_form.elements[element.name];
    
    console.log("checked: " + radios.value);

    // save currently checked radio
    last_simul_radio_state[form_id] = radios.value;
  }

});
