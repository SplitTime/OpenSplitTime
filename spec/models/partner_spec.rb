require 'rails_helper'

# t.integer  "event_id",                        null: false
# t.string   "link",                            null: false
# t.integer  "weight",              default: 1, null: false
# t.datetime "created_at",                      null: false
# t.datetime "updated_at",                      null: false
# t.string   "banner_file_name"
# t.string   "banner_content_type"
# t.integer  "banner_file_size"
# t.datetime "banner_updated_at"

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
