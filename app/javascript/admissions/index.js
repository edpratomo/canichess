$(document).on('turbolinks:load', function() {
  console.log("turbolinks:load TRIGGERED");
  $('#datetimepicker1').datetimepicker({
    locale: 'id',
    //format: 'L',
    format: 'DD/MM/YYYY',
    //defaultDate: moment().subtract(17, 'years').calendar()
  });
  $('#admission_name').focus();
});
