require 'rails_helper'

# t.integer  "event_id"
# t.string   "image"
# t.string   "link"
# t.integer  "weight"

RSpec.describe PartnerAd, type: :model do
  it { is_expected.to strip_attribute(:image).collapse_spaces }
  it { is_expected.to strip_attribute(:link).collapse_spaces }

  describe '#initialize' do
    it 'initializes with an event_id, an image URL, a link URL, and a weight' do
      expect { create(:partner_ad) }.not_to raise_error
    end
  end
end
