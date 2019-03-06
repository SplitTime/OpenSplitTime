import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["orgName", "orgDescription", "orgDropdown", "eventGroupName"];

    connect() {
        this.setOrgForm()
    }

    setOrgForm() {
        let orgId = this.orgDropdownTarget.value;
        let nameElement = this.orgNameTarget;
        let nameField = nameElement.querySelector('input');
        let descriptionElement = this.orgDescriptionTarget;
        let descriptionField = descriptionElement.querySelector('textarea');

        if (orgId === '') {
            nameElement.classList.remove('d-none');
            nameField.value = null;
            nameField.disabled = false;
            descriptionField.value = null;
            descriptionField.disabled = false;
        } else {
            Rails.ajax({
                type: "GET",
                url: "/api/v1/organizations/" + orgId,
                success: function (data) {
                    let attributes = data.data.attributes;
                    nameElement.classList.add('d-none');

                    console.log(attributes);

                    nameField.value = attributes.name;
                    nameField.disabled = true;
                    descriptionField.value = attributes.description;
                    descriptionField.disabled = true
                }
            })
        }
    }

    fillEventGroupName() {
        let orgName = this.orgNameTarget.querySelector('input').value;
        let eventGroupNameField = this.eventGroupNameTarget.querySelector('input');
        let eventGroupName = eventGroupNameField.value;

        if((orgName.length > 0) && (eventGroupName.length === 0)) {
            eventGroupNameField.value = new Date().getFullYear() + ' ' + orgName
        }
    }
}
