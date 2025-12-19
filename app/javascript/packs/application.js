// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
//import "@hotwired/turbo-rails"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

require("moment/locale/id")
require("tempusdominus-bootstrap-4")
import "datatables.net-bs4"
import "datatables.net-responsive-bs4"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

import 'bootstrap';
import bsCustomFileInput from 'bs-custom-file-input'

// https://stackoverflow.com/questions/62946298/uncaught-referenceerror-is-not-defined-in-rails-6-jquery-webpacker
window.jQuery = $;
window.$ = $;

window.Cookies = require("js-cookie");

document.addEventListener("turbolinks:load", () => {
  $('[data-toggle="tooltip"]').tooltip()

  var table;
  // Warning: Cannot reinitialise DataTable.
  // https://datatables.net/manual/tech-notes/3
  if ( $.fn.dataTable.isDataTable( '#datatable_with_search' ) ) {
    table = $('#datatable_with_search').DataTable();
  } else {
    table = $('#datatable_with_search').DataTable( {
      "responsive": true, "lengthChange": false, "autoWidth": false,
      "searching": true, "paging": true, "ordering": true, "info": true
    } );
  }

  bsCustomFileInput.init()
});

import '../stylesheets/scaffolds';
import '../stylesheets/application'; // This file will contain your custom CSS

require('admin-lte');

import toastr from 'toastr'
window.toastr = toastr

// import "@fortawesome/fontawesome-free/js/all";
require("@fortawesome/fontawesome-free");

import "../controllers";

window.BootstrapDialog = require("bootstrap4-dialog/dist/js/bootstrap-dialog.min");
