import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["categories", "dropdown"]

    replaceCategories() {
        let templateId = this.dropdownTarget.value;
        let categories = this.categoriesTarget;

        Rails.ajax({
            type: "GET",
            url: "/results_templates/" + templateId + "/categories",
            success: function (data, status, xml) {
                categories.innerHTML = xml.response
            }
        })
    }
}
