# frozen_string_literal: true

require 'rails_helper'

# t.integer  "course_id",                                                 null: false
# t.integer  "organization_id"
# t.string   "name",            limit: 64,                                null: false
# t.datetime "start_time"
# t.boolean  "concealed",                  default: false
# t.boolean  "available_live",             default: false
# t.string   "beacon_url"
# t.integer  "laps_required"
# t.uuid     "staging_id",                 default: "uuid_generate_v4()"
# t.string   "slug",                                                      null: false
# t.boolean  "auto_live_times",            default: false
# t.string   "home_time_zone",                                            null: false

RSpec.describe Event, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }

  describe 'initialize' do
    let(:course) { build_stubbed(:course) }
    let(:start_time) { DateTime.parse('2015-07-01 06:00:00-06:00') }
    let(:home_time_zone) { 'Mountain Time (US & Canada)' }

    it 'is valid when created with a course, name, start time, laps_required, and home_time_zone' do
      event = build_stubbed(:event, course: course)

      expect(event.course_id).to be_present
      expect(event.name).to be_present
      expect(event.start_time).to be_present
      expect(event.laps_required).to be_present
      expect(event.home_time_zone).to be_present
      expect(event).to be_valid
    end

    it 'is invalid without a course' do
      event = build_stubbed(:event, course: nil)
      expect(event).not_to be_valid
      expect(event.errors[:course_id]).to include("can't be blank")
    end

    it 'is invalid without a name' do
      event = build_stubbed(:event, name: nil, without_slug: true)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without a start date' do
      event = build_stubbed(:event, start_time: nil)
      expect(event).not_to be_valid
      expect(event.errors[:start_time]).to include("can't be blank")
    end

    it 'is invalid without a laps_required' do
      event = build_stubbed(:event, laps_required: nil)
      expect(event).not_to be_valid
      expect(event.errors[:laps_required]).to include("can't be blank")
    end

    it 'is invalid without a home_time_zone' do
      event = build_stubbed(:event, home_time_zone: nil)
      expect(event).not_to be_valid
      expect(event.errors[:home_time_zone]).to include("can't be blank")
    end

    it 'is invalid with a nonexistent home_time_zone' do
      event = build_stubbed(:event, home_time_zone: 'Narnia')
      expect(event).to be_invalid
      expect(event.errors[:home_time_zone]).to include("must be the name of an ActiveSupport::TimeZone object")
    end

    it 'does not permit duplicate names' do
      existing_event = create(:event)
      event = build_stubbed(:event, name: existing_event.name)
      expect(event).not_to be_valid
      expect(event.errors[:name]).to include('has already been taken')
    end
  end

  describe 'methods that produce lap_splits and time_points' do
    let(:event) { FactoryGirl.build_stubbed(:event, laps_required: 2) }
    let(:start_split) { FactoryGirl.build_stubbed(:start_split, id: 111) }
    let(:intermediate_split1) { FactoryGirl.build_stubbed(:split, id: 102) }
    let(:intermediate_split2) { FactoryGirl.build_stubbed(:split, id: 103) }
    let(:finish_split) { FactoryGirl.build_stubbed(:finish_split, id: 112) }
    let(:splits) { [start_split, intermediate_split1, intermediate_split2, finish_split] }

    describe '#required_lap_splits' do
      it 'returns an empty array when laps_required is zero' do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits).to eq([])
      end

      it 'returns an array whose size is equal to laps_required * number of splits' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
      end

      it 'returns an array of LapSplit objects ordered by lap, split distance, and bitkey' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_lap_splits = test_event.required_lap_splits
        expect(required_lap_splits.size).to eq(8)
        expect(required_lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
        expect(required_lap_splits.map(&:split).map(&:id)).to eq([111, 102, 103, 112] * 2)
      end
    end


    describe '#required_time_points' do
      it 'returns an empty array when laps_required is zero' do
        test_event = event
        test_event.laps_required = 0
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points).to eq([])
      end

      it 'returns an array whose size is equal to laps_required * number of sub_splits' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.size).to eq(12)
      end

      it 'returns an array of TimePoint objects ordered by lap, split distance, and bitkey' do
        test_event = event
        ordered_splits = splits
        allow_any_instance_of(Event).to receive(:ordered_splits).and_return(ordered_splits)
        required_time_points = test_event.required_time_points
        expect(required_time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
        expect(required_time_points.map(&:split_id)).to eq([111, 102, 102, 103, 103, 112] * 2)
        expect(required_time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
      end
    end
  end

  describe '#multiple_laps?' do
    it 'returns false if the event requires exactly one lap' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 1)
      expect(event.multiple_laps?).to be_falsey
    end

    it 'returns true if the event requires more than one lap' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 2)
      expect(event.multiple_laps?).to be_truthy
    end

    it 'returns true if the event requires zero (i.e. unlimited) laps' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 0)
      expect(event.multiple_laps?).to be_truthy
    end
  end

  describe '#maximum_laps' do
    it 'returns laps_required when laps_required is 1' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 1)
      expect(event.maximum_laps).to eq(1)
    end

    it 'returns laps_required when laps_required is greater than 1' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 3)
      expect(event.maximum_laps).to eq(3)
    end

    it 'returns nil when laps_required is 0' do
      event = FactoryGirl.build_stubbed(:event, laps_required: 0)
      expect(event.maximum_laps).to eq(nil)
    end
  end

  describe '#pick_partner_with_banner' do
    context 'where multiple partners exist for both the subject event and another event' do
      let!(:event) { create(:event) }
      let!(:wrong_event) { create(:event) }
      let!(:related_partners_with_banners) { create_list(:partner, 3, :with_banner, event: event) }
      let!(:related_partners_without_banners) { create_list(:partner, 3, event: event) }
      let!(:unrelated_partners_with_banners) { create_list(:partner, 3, :with_banner, event: wrong_event) }
      let!(:unrelated_partners_without_banners) { create_list(:partner, 3, event: wrong_event) }

      it 'returns a random partner with a banner for the event' do
        partners = []
        100.times { partners << event.pick_partner_with_banner }
        expect(partners.map(&:event_id).uniq).to eq([event.id])
        expect(partners.map(&:banner_file_name)).to all (be_present)
      end
    end

    context 'where multiple partners with banners for the event exist and one is weighted more heavily' do
      # Four partners with weight: 1 and one partner with weight: 10 means the weighted partner should receive,
      # on average, about 71% of hits.
      let!(:event) { create(:event) }
      let!(:weighted_partner) { create(:partner, :with_banner, event: event, weight: 10) }
      let!(:unweighted_partners) { create_list(:partner, 4, :with_banner, event: event) }

      it 'returns a random partner giving weight to the weighted partner' do
        partners = []
        100.times { partners << event.pick_partner_with_banner }
        partners_count = partners.count_by(&:id)
        expect(partners_count[weighted_partner.id]).to be > 50
        unweighted_partners.each do |unweighted_partner|
          expect(partners_count[unweighted_partner.id]).to be_between(1, 20).inclusive
        end
      end
    end

    context 'where no partners with banners for the event exist' do
      let!(:event) { create(:event) }

      it 'returns nil' do
        create(:partner, event: event) # Without a banner
        expect(event.pick_partner_with_banner).to be_nil
      end
    end
  end

  describe '#live_entry_attributes' do
    let(:event) { build_stubbed(:event_with_standard_splits) }
    let(:splits) { event.splits.sort_by(&:distance_from_start) }

    it 'returns an array of information for building live entry screens' do
      allow(event).to receive(:ordered_splits).and_return(splits)
      split = splits.second
      expected = {title: split.base_name,
                  entries: [{split_id: split.id, sub_split_kind: 'in', label: "#{split.base_name} In"},
                            {split_id: split.id, sub_split_kind: 'out', label: "#{split.base_name} Out"}]}
      attributes = event.live_entry_attributes
      expect(attributes.size).to eq(splits.size)
      expect(attributes.second).to eq(expected)
    end
  end

  describe '#start_time_in_home_zone' do
    context 'when the event specifies a valid home_time_zone' do
      let(:event) { build_stubbed(:event, home_time_zone: 'Eastern Time (US & Canada)') }

      it 'returns the start_time in the time zone specified by event.home_time_zone' do
        event.start_time = DateTime.parse('2017-07-01T06:00+00:00')
        expect(event.start_time_in_home_zone.time_zone.name).to eq(event.home_time_zone)
        expect(event.start_time_in_home_zone.to_s).to eq('2017-07-01 02:00:00 -0400')
      end

      it 'properly senses daylight savings time where applicable' do
        event.start_time = DateTime.parse('2017-12-15T06:00+00:00')
        expect(event.start_time_in_home_zone.time_zone.name).to eq(event.home_time_zone)
        expect(event.start_time_in_home_zone.to_s).to eq('2017-12-15 01:00:00 -0500')
      end
    end

    context 'when the event home_time_zone is nil' do
      let(:event) { build_stubbed(:event, start_time: DateTime.parse('2017-07-01T06:00+00:00'), home_time_zone: nil) }

      it 'returns nil' do
        expect(event.start_time_in_home_zone).to be_nil
      end
    end

    context 'when the event start_time is nil' do
      let(:event) { build_stubbed(:event, start_time: nil, home_time_zone: 'Eastern Time (US & Canada)') }

      it 'returns nil' do
        expect(event.start_time_in_home_zone).to be_nil
      end
    end
  end

  describe '#start_time_in_home_zone=' do
    context 'when home_time_zone exists' do
      let(:event) { build_stubbed(:event, home_time_zone: 'Eastern Time (US & Canada)') }

      it 'converts the string based on the specified home_time_zone' do
        event.start_time_in_home_zone = '07/01/2017 06:00:00'
        start_time = event.start_time.in_time_zone('GMT')
        expect(start_time).to eq('2017-07-01 10:00:00 -0000')
      end

      it 'works properly with a 24-hour time' do
        event.start_time_in_home_zone = '07/01/2017 16:00:00'
        start_time = event.start_time.in_time_zone('GMT')
        expect(start_time).to eq('2017-07-01 20:00:00 -0000')
      end

      it 'works properly with AM/PM time' do
        event.start_time_in_home_zone = '07/01/2017 04:00:00 PM'
        start_time = event.start_time.in_time_zone('GMT')
        expect(start_time).to eq('2017-07-01 20:00:00 -0000')
      end

      it 'works properly with date formatted in yyyy-mm-dd style' do
        event.start_time_in_home_zone = '2017-07-01 16:00:00'
        start_time = event.start_time.in_time_zone('GMT')
        expect(start_time).to eq('2017-07-01 20:00:00 -0000')
      end

      it 'works properly regardless of daylight savings time' do
        event.start_time_in_home_zone = '2017-12-15 16:00:00'
        start_time = event.start_time.in_time_zone('GMT')
        expect(start_time).to eq('2017-12-15 21:00:00 -0000')
      end
    end

    context 'when home_time_zone does not exist' do
      let(:event) { build_stubbed(:event, home_time_zone: nil) }

      it 'raises an error' do
        expect { event.start_time_in_home_zone = '2017-07-01 06:00:00' }
            .to raise_error(/start_time_in_home_zone cannot be set without a valid home_time_zone/)
      end
    end
  end

  describe '#events_within_group' do
    subject { event.events_within_group }
    let(:event_group_1) { create(:event_group) }
    let(:event_group_2) { create(:event_group) }
    let(:event) { create(:event, event_group: event_group_1) }
    let(:event_same_group) { create(:event, event_group: event_group_1) }
    let(:event_different_group) { create(:event, event_group: event_group_2) }

    it 'returns the event and other members of the group as an array' do
      expect(subject).to include(event)
      expect(subject).to include(event_same_group)
      expect(subject).not_to include(event_different_group)
    end
  end

  describe '#simple?' do
    subject { event.simple? }
    let(:event) { build_stubbed(:event, splits: splits, laps_required: laps_required)}

    context 'when the event has only a start and finish split and only one lap' do
      let(:splits) { build_stubbed_list(:split, 2) }
      let(:laps_required) { 1 }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the event has only a start and finish split but multiple laps' do
      let(:splits) { build_stubbed_list(:split, 2) }
      let(:laps_required) { 0 }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when the event has more than two splits and only one lap' do
      let(:splits) { build_stubbed_list(:split, 3) }
      let(:laps_required) { 1 }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
