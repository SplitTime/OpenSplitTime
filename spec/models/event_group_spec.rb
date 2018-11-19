# frozen_string_literal: true

require 'rails_helper'

# t.string "name"
# t.integer "organization_id"
# t.boolean "available_live", default: false
# t.boolean "auto_live_times", default: true
# t.boolean "concealed", default: true
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.integer "created_by"
# t.integer "updated_by"
# t.string "slug"
# t.integer "data_entry_grouping_strategy", default: 0
# t.boolean "monitor_pacers", default: false

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

  describe '#pick_partner_with_banner' do
    context 'where multiple partners exist for both the subject event_group and another event_group' do
      let!(:event_group) { create(:event_group) }
      let!(:wrong_event_group) { create(:event_group) }
      let!(:related_partners_with_banners) { create_list(:partner, 3, :with_banner, event_group: event_group) }
      let!(:related_partners_without_banners) { create_list(:partner, 3, event_group: event_group) }
      let!(:unrelated_partners_with_banners) { create_list(:partner, 3, :with_banner, event_group: wrong_event_group) }
      let!(:unrelated_partners_without_banners) { create_list(:partner, 3, event_group: wrong_event_group) }

      it 'returns a random partner with a banner for the event_group' do
        partners = []
        100.times { partners << event_group.pick_partner_with_banner }
        expect(partners.map(&:event_group).uniq).to eq([event_group])
        expect(partners.map(&:banner_file_name)).to all (be_present)
      end
    end

    context 'where multiple partners with banners for the event_group exist and one is weighted more heavily' do
      # Four partners with weight: 1 and one partner with weight: 10 means the weighted partner should receive,
      # on average, about 71% of hits.
      let!(:event_group) { create(:event_group) }
      let!(:weighted_partner) { create(:partner, :with_banner, event_group: event_group, weight: 10) }
      let!(:unweighted_partners) { create_list(:partner, 4, :with_banner, event_group: event_group) }

      it 'returns a random partner giving weight to the weighted partner' do
        partners = []
        100.times { partners << event_group.pick_partner_with_banner }
        partners_count = partners.count_by(&:id)
        expect(partners_count[weighted_partner.id]).to be > 40
        unweighted_partners.each do |unweighted_partner|
          expect(partners_count[unweighted_partner.id] || 0).to be_between(0, 20).inclusive
        end
      end
    end

    context 'where no partners with banners for the event_group exist' do
      let!(:event_group) { create(:event_group) }

      it 'returns nil' do
        create(:partner, event_group: event_group) # Without a banner
        expect(event_group.pick_partner_with_banner).to be_nil
      end
    end
  end
end
