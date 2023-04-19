import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {

  static targets = ["countrySelect", "stateSelectWrapper"]

  getSubregions() {
    const countryCode = this.countrySelectTarget.value
    const model = this.data.get("model")
    const selectWrapper = this.stateSelectWrapperTarget

    Rails.ajax({
      type: "GET",
      url: "/carmen/subregion_options?model=" + model + "&parent_region=" + countryCode,
      success: function (data, status, xml) {
        selectWrapper.outerHTML = xml.response
      }
    })
  }
}
