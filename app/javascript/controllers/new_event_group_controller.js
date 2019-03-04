import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["orgName", "orgDescription", "orgDropdown"];

    replaceOrgForm() {
        let orgId = this.orgDropdownTarget.value;
        let nameField = this.orgNameTarget;
        let descriptionField = this.orgDescriptionTarget;

        if (orgId === '') {
            nameField.classList.remove('d-none');
            nameField.value = null;
            descriptionField.value = null
        } else {
            Rails.ajax({
                type: "GET",
                url: "/api/v1/organizations/" + orgId,
                success: function (data) {
                    let attributes = data.data.attributes;
                    nameField.classList.add('d-none');

                    debugger;

                    nameField.querySelector('input').value = attributes.name;
                    descriptionField.querySelector('input').value = attributes.description
                }
            })
        }
    }
}
