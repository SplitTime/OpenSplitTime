# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Partner, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:banner_link).collapse_spaces }

  describe '#initialize' do
    it 'initializes with an event_id, a name, and a weight' do
      partner = build_stubbed(:partner)
      expect(partner.event_group_id).to be_present
      expect(partner.name).to be_present
      expect(partner.weight).to be_present
      expect(partner).to be_valid
    end
  end
end
