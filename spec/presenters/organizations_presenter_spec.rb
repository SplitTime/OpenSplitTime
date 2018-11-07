# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrganizationsPresenter do
  subject { OrganizationsPresenter.new(organizations, params, current_user) }
  let(:organizations) { build_stubbed_list(:organization, 2) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:current_user) { build_stubbed(:admin) }

  describe '#organizations' do
    it 'returns the related organizations' do
      expect(subject.organizations).to eq(organizations)
    end
  end

  describe '#events_count' do
    let(:organizations) { [organization] }
    let(:organization) { build_stubbed(:organization) }
    let(:event_group) { build_stubbed(:event_group, organization: organization) }

    before do
      allow(event_group).to receive(:events).and_return(events)
      allow(subject).to receive(:event_groups).and_return([event_group])
    end


    context 'when the organization has associated events' do
      let(:events) { build_stubbed_list(:event, 2, event_group: event_group) }

      it 'returns a count of the events related to a given organization' do
        expect(subject.events_count(organization)).to eq(2)
      end
    end

    context 'when the organization has no associated events' do
      let(:events) { [] }

      it 'returns 0' do
        expect(subject.events_count(organization)).to eq(0)
      end
    end
  end
end
