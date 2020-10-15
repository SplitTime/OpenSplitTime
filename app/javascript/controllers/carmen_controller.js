import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["countrySelect", "stateSelectWrapper"]

    getSubregions() {
        const selectWrapper = this.stateSelectWrapperTarget
        const countryCode = this.countrySelectTarget.value

        Rails.ajax({
            type: "GET",
            url: "/carmen/subregion_options?parent_region=" + countryCode,
            success: function (data, status, xml) {
                selectWrapper.outerHTML = xml.response
            }
        })
    }
}
