$(document).on('turbolinks:load', function () {
  console.log("turbolinks:load TRIGGERED");
  var last_radio_state = [];

  getRadioByValue = function(radios, value) {
    for (var i = 0; i < radios.length; i++) {       
      if (radios[i].value == value) {
        return radios[i];
      }
    }
  }

  getCheckedRadio = function(radios) {
    for (var i = 0; i < radios.length; i++) {       
      if (radios[i].checked) {
        return radios[i];
      }
    }
  }

  updateRadio = function(element) {
    var form_action = element.form.action;
    var form_id = element.form.id;
    var found_form = document.querySelector("#" + form_id);
    var radios = found_form.elements[element.name];
    var last_state = last_radio_state[form_id];

    var form_ary = form_id.split("_");
    var td_board_id = "#td_board_" + form_ary.slice(-1);

    console.log("[update_Radio] form_action: " + form_action);

    $.ajax({
      url: form_action + '.json',
      type: 'PATCH',
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      data: { _method:'patch', board: { result: element.value } },
      dataType: 'json',
      'error' : function(response) {
          console.log("response: " + response.status);
          console.log("reverting to: " + last_state);
          // revert the change
          if (last_state) {
            var found_radio = getRadioByValue(radios, last_state);
            found_radio.checked = true;
          } else {
            element.checked = false;
          }
      },
      'success': function(data) {
        $(td_board_id).removeClass("bg-warning");
        console.log("group all_completed? " + data["group"]["all_completed"]);
        console.log("all_completed? " + data["tournament"]["all_completed"]);
        if (data["group"]["all_completed"]) {
          $("#finalize_enabled").show();
          $("#finalize_disabled").hide();
        } else if (data["tournament"]["all_completed"]) {
        //if (data["tournament"]["all_completed"]) {
          $("#finalize_enabled").show();
          $("#finalize_disabled").hide();
        }
      },
    });
  }

  checkRadio = function(element) {
    var form_id = element.form.id;
    var found_form = document.querySelector("#" + form_id);
    
    // RadioNodeList
    var radios = found_form.elements[element.name];
    
    console.log("checked: " + radios.value);

    // save currently checked radio
    last_radio_state[form_id] = radios.value;
  }

  updateCheckBox = function(element) {
    var form_action = element.form.action;
    var form_id = element.form.id;
    var found_form = document.querySelector("#" + form_id);
    var check_box = found_form.elements[element.name];

    var form_ary = form_id.split("_");
    console.log("[updateCheckBox] form_action: " + form_action);

    var $c_form = $(element).closest('form');
    console.log("[updateCheckBox] element id: " + element.id);

    $.ajax({
      url: form_action + '.json',
      type: 'PATCH',
      beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
      data: { _method:'patch', board: { walkover: element.checked } },
      dataType: 'json',
      'error' : function(response) {
          console.log("response: " + response.status);
          console.log("reverting to: false");
          element.checked = false;
      },
      'success': function(data) {
        console.log("walkover changed");
      },
    });
  }

});
