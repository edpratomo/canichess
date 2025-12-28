// controllers/datatable_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Datatable controller connected")

    if ($.fn.DataTable.isDataTable(this.element)) {
      console.log("DataTable already initialized on ", this.element)
      return
    } else {
      console.log("Initializing DataTable ")
      $(this.element).DataTable()
    }
  }
  
}
