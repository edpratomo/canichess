$(document).on('turbolinks:load ready', function () {

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

});
