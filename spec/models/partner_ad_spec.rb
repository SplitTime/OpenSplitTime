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

RSpec.describe PartnerAd, type: :model do
  it { is_expected.to strip_attribute(:link).collapse_spaces }

  describe '#initialize' do
    it 'initializes with an event_id, a link URL, and a weight' do
      expect { create(:partner_ad) }.not_to raise_error
    end
  end
end
