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
            descriptionField.placeholder = 'Say something about your organization'
        } else {
            Rails.ajax({
                type: "GET",
                url: "/api/v1/organizations/" + orgId,
                success: function (data) {
                    let attributes = data.data.attributes;

                    nameElement.classList.add('d-none');
                    nameField.value = attributes.name;
                    nameField.disabled = true;
                    descriptionField.value = attributes.description;
                    descriptionField.disabled = true;
                    descriptionField.placeholder = 'No description yet provided'
                }
            })
        }
    }

    fillEventGroupName() {
        let eventGroupNameField = this.eventGroupNameTarget.querySelector('input');
        let eventGroupName = eventGroupNameField.value;
        let select = this.orgDropdownTarget;
        let orgName = '';

        if (select.value === '') {
            orgName = this.orgNameTarget.querySelector('input').value;
        } else {
            orgName = select.options[select.selectedIndex].text
        }

        let orgNameExists = (orgName.length > 0);
        let groupNameReplaceable = (eventGroupName.length === 0) || this.data.get('nameSource') === 'auto';

        if (orgNameExists && groupNameReplaceable) {
            eventGroupNameField.value = new Date().getFullYear() + ' ' + orgName;
            this.data.set('nameSource', 'auto')
        }
    }

    freezeEventGroupName() {
        this.data.set('nameSource', 'manual')
    }
}
