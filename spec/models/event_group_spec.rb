# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventGroup, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe '#initialize' do
    subject { EventGroup.new(name: name, organization: organization, home_time_zone: home_time_zone) }
    let(:name) { 'Test Name' }
    let(:organization) { organizations(:hardrock) }
    let(:home_time_zone) { 'Arizona' }

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

    context 'without a home_time_zone' do
      let(:home_time_zone) { nil }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors.full_messages).to include(/Home time zone can't be blank/)
      end
    end

    context 'with a nonexistent home_time_zone' do
      let(:home_time_zone) { 'Narnia' }

      it 'is invalid' do
        expect(subject).to be_invalid
        expect(subject.errors[:home_time_zone]).to include(/must be the name of an ActiveSupport::TimeZone object/)
      end
    end
  end

  describe "after_save" do
    let(:event_group) { event_groups(:dirty_30) }
    let(:events) { event_group.events }

    it "touches all events" do
      events.each do |event|
        event.reload
        expect(event.updated_at > 1.minute.ago).not_to eq(true)
      end

      expect(event_group).to be_available_live
      event_group.update(available_live: false)

      events.each do |event|
        event.reload
        expect(event.updated_at > 1.minute.ago).to eq(true)
      end
    end

    describe "conforms the concealed status of related records" do
      before do
        subject_event_group.update(concealed: subject_event_group_existing_concealed)
        other_event_group.update(concealed: other_event_group_concealed)
      end

      shared_examples "makes the conforming record visible" do
        it "makes the conforming record visible" do
          expect(conforming_record.reload).to be_concealed
          subject_event_group.update(concealed: subject_event_group_concealed)
          expect(conforming_record.reload).not_to be_concealed
        end
      end

      shared_examples "conceals the conforming record" do
        it "conceals the conforming record" do
          expect(conforming_record.reload).not_to be_concealed
          subject_event_group.update(concealed: subject_event_group_concealed)
          expect(conforming_record.reload).to be_concealed
        end
      end

      shared_examples "does not conceal the conforming record" do
        it "does not conceal the conforming record" do
          expect(conforming_record.reload).not_to be_concealed
          subject_event_group.update(concealed: subject_event_group_concealed)
          expect(conforming_record.reload).not_to be_concealed
        end
      end

      shared_examples "conceals and makes visible the conforming record" do
        context "when hiding the subject event group" do
          let(:subject_event_group_existing_concealed) { false }
          let(:subject_event_group_concealed) { true }
          context "when another event group for the organization is visible" do
            let(:other_event_group_concealed) { false }
            include_examples "does not conceal the conforming record"
          end

          context "when all other event groups for the organization are concealed" do
            let(:other_event_group_concealed) { true }
            include_examples "conceals the conforming record"
          end
        end

        context "when making the subject event group visible" do
          let(:subject_event_group_existing_concealed) { true }
          let(:subject_event_group_concealed) { false }
          context "when another event group for the organization is visible" do
            let(:other_event_group_concealed) { false }
            include_examples "does not conceal the conforming record"
          end

          context "when all other event groups for the organization are concealed" do
            let(:other_event_group_concealed) { true }
            include_examples "makes the conforming record visible"
          end
        end
      end

      describe "conforms the concealed status of the organization" do
        let(:organization) { subject_event_group.organization }
        let(:subject_event_group) { event_groups(:rufa_2017) }
        let(:other_event_group) { event_groups(:rufa_2016) }
        let(:conforming_record) { organization }

        include_examples "conceals and makes visible the conforming record"
      end

      describe "conforms concealed status of people" do
        let(:person) { people(:finished_first_colorado_us) }
        let(:subject_event_group) { event_groups(:sum) }
        let(:other_event_group) { event_groups(:dirty_30) }
        let(:conforming_record) { person }

        include_examples "conceals and makes visible the conforming record"
      end

      describe "conforms concealed status of courses" do
        let(:course) { courses(:rufa_course) }
        let(:subject_event_group) { event_groups(:rufa_2017) }
        let(:other_event_group) { event_groups(:rufa_2016) }
        let(:conforming_record) { course }

        include_examples "conceals and makes visible the conforming record"
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
        expect(partners.map(&:id).uniq).to match_array(related_partners_with_banners.map(&:id))
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
      let(:event_group) { create(:event_group) }

      it 'returns nil' do
        create(:partner, event_group: event_group) # Without a banner
        expect(event_group.pick_partner_with_banner).to be_nil
      end
    end
  end
end
