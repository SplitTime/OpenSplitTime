require 'rails_helper'

# t.string   "name"
# t.integer  "organization_id"
# t.boolean  "available_live",  default: false
# t.boolean  "auto_live_times", default: false
# t.boolean  "concealed",       default: false
# t.string   "slug"

RSpec.describe EventGroup, type: :model do

  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe '#initialize' do
    it 'initializes with a name and an organization' do
      event_group = build_stubbed(:event_group)
      expect(event_group.name).to be_present
      expect(event_group.organization).to be_present
      expect(event_group).to be_valid
    end
  end
end
