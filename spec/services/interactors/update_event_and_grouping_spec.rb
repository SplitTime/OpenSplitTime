require 'rails_helper'

RSpec.describe Interactors::UpdateEventAndGrouping do

  describe '.perform!' do
    context 'when the event is changing to an existing event_group and the old event_group is orphaned' do
      let!(:organization) { create(:organization) }
      let!(:old_event_group) { create(:event_group, organization: organization) }
      let!(:event) { create(:event, event_group: old_event_group) }
      let!(:new_event_group) { create(:event_group, organization: organization) }
      let(:params) { {event_group_id: new_event_group.id} }

      it 'updates the event and destroys the orphaned event_group' do
        expect(EventGroup.all.size).to eq(2)
        event.assign_attributes(params)
        response = Interactors::UpdateEventAndGrouping.perform!(event)
        event.reload
        expect(event.event_group_id).to eq(new_event_group.id)
        expect(EventGroup.all.size).to eq(1)
        expect(EventGroup.first).to eq(new_event_group)
        expect(response.message).to match(/was saved/)
        expect(response.message).to match(/was deleted/)
      end
    end

    context 'when the event is changing to a new event_group and the old event_group has one remaining event' do
      let!(:old_event_group) { create(:event_group) }
      let!(:event) { create(:event, event_group: old_event_group) }
      let!(:other_event) { create(:event, event_group: old_event_group) }
      let(:params) { {event_group_id: nil} }

      it 'creates a new event and assigns it to the subject event' do
        expect(EventGroup.all.size).to eq(1)
        expect(EventGroup.first.events.size).to eq(2)
        event.assign_attributes(params)
        response = Interactors::UpdateEventAndGrouping.perform!(event)
        event.reload
        expect(EventGroup.all.size).to eq(2)
        expect(event.event_group_id).not_to be_nil
        expect(event.event_group_id).not_to eq(old_event_group.id)
        expect(response.message).to match(/was saved/)
        expect(response.message).not_to match(/was deleted/)
      end
    end

    context 'when the event cannot be changed to the requested group' do
      let!(:organization) { create(:organization) }
      let!(:other_organization) { create(:organization) }
      let!(:old_event_group) { create(:event_group, organization: organization) }
      let!(:event) { create(:event, event_group: old_event_group) }
      let!(:new_event_group) { create(:event_group, organization: other_organization) }
      let(:params) { {event_group_id: new_event_group.id} }

      it 'creates no new records and changes no existing records but returns a descriptive error report' do
        expect(EventGroup.all.size).to eq(2)
        event.assign_attributes(params)
        response = Interactors::UpdateEventAndGrouping.perform!(event)
        event.reload
        expect(event.event_group_id).to eq(old_event_group.id)
        expect(EventGroup.all.size).to eq(2)
        expect(response.message).to eq('Event or event group could not be updated')
        expect(response.errors.first[:title]).to eq('Event group organizations do not match')
        expect(response.errors.first[:detail][:message]).to match(/The event cannot be updated because/)
      end
    end
  end
end
