require 'rails_helper'

# t.string   "name"
# t.integer  "organization_id"
# t.boolean  "available_live",  default: false
# t.boolean  "auto_live_times", default: false
# t.boolean  "concealed",       default: false
# t.string   "slug"
# t.boolean  "monitor_pacers", default: false

RSpec.describe EventGroup, type: :model do

  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe '#initialize' do
    subject { build_stubbed(:event_group) }
    
    it 'initializes with a name and an organization' do
      expect(subject.name).to be_present
      expect(subject.organization).to be_present
      expect(subject).to be_valid
    end
  end

  describe '#multiple_laps?' do
    subject { build_stubbed(:event_group, events: events) }
    let(:event_1) { build_stubbed(:event, laps_required: 1) }
    let(:event_2) { build_stubbed(:event, laps_required: 1) }
    let(:event_3) { build_stubbed(:event, laps_required: 0) }

    context 'when no events are multi lap' do
      let(:events) { [event_1, event_2] }

      it 'returns false' do
        expect(subject.multiple_laps?).to eq(false)
      end
    end

    context 'when any event is multi lap' do
      let(:events) { [event_1, event_3] }

      it 'returns true' do
        expect(subject.multiple_laps?).to eq(true)
      end
    end
  end
end
