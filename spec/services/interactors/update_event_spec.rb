require 'rails_helper'

RSpec.describe Interactors::UpdateEvent do

  describe '.perform!' do
    context 'when the event is changing to an existing event_group and the old event_group is orphaned' do
      let!(:old_event_group) { create(:event_group) }
      let!(:event) { create(:event, event_group: old_event_group) }
      let!(:new_event_group) { create(:event_group) }
      let(:params) { {event_group_id: new_event_group.id} }

      it 'updates the event and destroys the orphaned event_group' do
        expect(EventGroup.all.size).to eq(2)
        event.assign_attributes(params)
        Interactors::UpdateEvent.perform!(event)
        event.reload
        expect(event.event_group_id).to eq(new_event_group.id)
        expect(EventGroup.all.size).to eq(1)
        expect(EventGroup.first).to eq(new_event_group)
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
        Interactors::UpdateEvent.perform!(event)
        event.reload
        expect(EventGroup.all.size).to eq(2)
        expect(event.event_group_id).not_to be_nil
        expect(event.event_group_id).not_to eq(old_event_group.id)
      end
    end
  end
end
