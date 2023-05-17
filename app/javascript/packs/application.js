// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

require("moment/locale/id")
require("tempusdominus-bootstrap-4")

Rails.start()
Turbolinks.start()
ActiveStorage.start()

import 'bootstrap';

// https://stackoverflow.com/questions/62946298/uncaught-referenceerror-is-not-defined-in-rails-6-jquery-webpacker
window.jQuery = $;
window.$ = $;

window.Cookies = require("js-cookie");

document.addEventListener("turbolinks:load", () => {
  $('[data-toggle="tooltip"]').tooltip()
});

import '../stylesheets/scaffolds';
import '../stylesheets/application'; // This file will contain your custom CSS

require('admin-lte');

// import "@fortawesome/fontawesome-free/js/all";
require("@fortawesome/fontawesome-free")
