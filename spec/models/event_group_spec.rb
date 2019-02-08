# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventGroup, type: :model do

  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe '#initialize' do
    subject { EventGroup.new(name: name, organization: organization) }
    let(:name) { 'Test Name' }
    let(:organization) { organizations(:hardrock) }

    context 'with a name and an organization' do
      it 'initializes' do
        expect(subject).to be_valid
      end
    end

    context 'without a name' do
      let(:name) { nil }

      it 'is not valid' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages).to include(/Name can't be blank/)
      end
    end

    context 'without an organization' do
      let(:organization) { nil }

      it 'is not valid' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages).to include(/Organization can't be blank/)
      end
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
