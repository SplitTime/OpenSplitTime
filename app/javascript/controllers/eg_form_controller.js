import {Controller} from "stimulus"

export default class extends Controller {

    static targets = ["orgDescription", "orgDropdown", "eventGroupName"];

    connect() {
        this.setOrgForm()
    }

    setOrgForm() {
        let orgId = this.orgDropdownTarget.value;
        let orgDescription = this.orgDescriptionTarget;

        if (orgId === '') {
            orgDescription.innerHTML = null
        } else {
            Rails.ajax({
                type: "GET",
                url: "/api/v1/organizations/" + orgId,
                success: function (data, status, xml) {
                    orgDescription.innerHTML = data.data.attributes.description
                }
            })
        }
    }

    fillEventGroupName() {
        let eventGroupNameField = this.eventGroupNameTarget.querySelector('input');
        let eventGroupName = eventGroupNameField.value;
        let select = this.orgDropdownTarget;
        let orgName = '';
        if (select.value !== '') {
            orgName = select.options[select.selectedIndex].text
        }

        let orgNameExists = (orgName.length > 0);
        let groupNameReplaceable = (eventGroupName.length === 0) || this.data.get('nameSource') === 'auto';

        if (groupNameReplaceable) {
            if (orgNameExists) {
                eventGroupNameField.value = new Date().getFullYear() + ' ' + orgName
            } else {
                eventGroupNameField.value = ''
            }
            this.data.set('nameSource', 'auto')
        }
    }

    freezeEventGroupName() {
        this.data.set('nameSource', 'manual')
    }
}
