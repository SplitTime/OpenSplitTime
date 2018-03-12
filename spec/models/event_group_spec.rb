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
    subject { build_stubbed(:event_group) }
    
    it 'initializes with a name and an organization' do
      expect(subject.name).to be_present
      expect(subject.organization).to be_present
      expect(subject).to be_valid
    end
  end
end
