# frozen_string_literal: true

require 'rails_helper'

# t.integer "event_id", null: false
# t.integer "person_id"
# t.string "wave"
# t.integer "bib_number"
# t.string "city", limit: 64
# t.string "state_code", limit: 64
# t.integer "age"
# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.integer "created_by"
# t.integer "updated_by"
# t.string "first_name"
# t.string "last_name"
# t.integer "gender"
# t.string "country_code", limit: 2
# t.date "birthdate"
# t.integer "data_status"
# t.string "beacon_url"
# t.string "report_url"
# t.string "phone", limit: 15
# t.string "email"
# t.string "slug", null: false
# t.boolean "checked_in", default: false
# t.string "photo_file_name"
# t.string "photo_content_type"
# t.integer "photo_file_size"
# t.datetime "photo_updated_at"
# t.string "emergency_contact"
# t.string "emergency_phone"

RSpec.describe Effort, type: :model do
  include BitkeyDefinitions

  it_behaves_like 'data_status_methods'
  it_behaves_like 'auditable'
  it_behaves_like 'matchable'
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }
  it { is_expected.to localize_time_attribute(:scheduled_start_time) }

  describe 'validations' do
    context 'for validations independent of existing database records' do
      let(:course) { build_stubbed(:course) }
      let(:event) { build_stubbed(:event, course: course) }
      let(:person) { build_stubbed(:person) }

      it 'saves a generic factory-created record to the database' do
        effort = create(:effort)
        expect(Effort.count).to eq(1)
        expect(Effort.first).to eq(effort)
      end

      it 'is valid when created with an event_id, first_name, last_name, and gender' do
        effort = build_stubbed(:effort, event: event)
        expect(effort.event_id).to be_present
        expect(effort.first_name).to be_present
        expect(effort.last_name).to be_present
        expect(effort.gender).to be_present
        expect(effort).to be_valid
      end

      it 'is invalid without an event_id' do
        effort = build_stubbed(:effort, event_id: nil)
        expect { effort.valid? }.to raise_error Module::DelegationError
        expect(effort.errors[:event_id]).to include("can't be blank")
      end

      it 'is invalid without a first_name' do
        effort = build_stubbed(:effort, event: event, first_name: nil)
        expect(effort).not_to be_valid
        expect(effort.errors[:first_name]).to include("can't be blank")
      end

      it 'is invalid without a last_name' do
        effort = build_stubbed(:effort, event: event, last_name: nil)
        expect(effort).not_to be_valid
        expect(effort.errors[:last_name]).to include("can't be blank")
      end

      it 'is invalid without a gender' do
        effort = build_stubbed(:effort, event: event, gender: nil)
        expect(effort).not_to be_valid
        expect(effort.errors[:gender]).to include("can't be blank")
      end
    end

    context 'for validations dependent on existing database records' do
      let(:event) { create(:event) }
      let(:other_event) { build_stubbed(:event, event_group: existing_effort.event.event_group) }
      let(:person_1) { create(:person) }
      let(:person_2) { create(:person) }
      let!(:existing_effort) { create(:effort, event: event, person: person_1, bib_number: 20) }

      it 'does not permit more than one effort by a person in a given event group' do
        effort = build_stubbed(:effort, event: event, person: person_1)
        expect(effort).not_to be_valid
        expect(effort.errors[:person]).to include(/has already been entered in/)
      end

      it 'permits more than one effort in a given event with unassigned people' do
        effort = build_stubbed(:effort, event: event, person: nil)
        expect(effort).to be_valid
      end

      it 'permits more than one effort in a given event with different people' do
        effort = build_stubbed(:effort, event: event, person: person_2)
        expect(effort).to be_valid
      end

      it 'does not permit duplicate bib_numbers within a given event' do
        effort = build_stubbed(:effort, event: event, bib_number: existing_effort.bib_number)
        expect(effort).not_to be_valid
        expect(effort.errors[:bib_number]).to include(/already exists/)
      end

      it 'does not permit duplicate bib_numbers within a given event_group' do
        effort = build_stubbed(:effort, event: other_event, bib_number: existing_effort.bib_number)
        expect(effort).not_to be_valid
        expect(effort.errors[:bib_number]).to include(/already exists/)
      end
    end
  end

  describe '#reset_age_from_birthdate' do
    subject { build_stubbed(:effort, event: event, age: age, birthdate: birthdate) }
    let(:event) { build_stubbed(:event, start_time: '2018-10-31 06:00:00') }

    context 'when age is nil and birthdate is provided' do
      let(:age) { nil }
      let(:birthdate) { '1967-01-01' }

      it 'sets the age from the birthdate' do
        subject.reset_age_from_birthdate
        expect(subject.age).to eq(51)
      end
    end

    context 'when age is provided and birthdate is nil' do
      let(:age) { 51 }
      let(:birthdate) { nil }

      it 'does not change age' do
        subject.reset_age_from_birthdate
        expect(subject.age).to eq(51)
      end
    end

    context 'when both age and birthdate are provided' do
      let(:age) { 40 }
      let(:birthdate) { '1967-01-01' }

      it 'sets the age from the birthdate' do
        subject.reset_age_from_birthdate
        expect(subject.age).to eq(51)
      end
    end

    context 'when neither age nor birthdate is provided' do
      let(:age) { nil }
      let(:birthdate) { nil }

      it 'does not attempt to set age' do
        subject.reset_age_from_birthdate
        expect(subject.age).to be_nil
      end
    end
  end

  describe '#current_age_approximate' do
    subject { build_stubbed(:effort, event: event, age: age) }
    let(:event) { build_stubbed(:event, start_time: start_time) }

    context 'when age is not present' do
      let(:age) { nil }
      let(:start_time) { Time.current - 2.years }

      it 'returns nil' do
        expect(subject.current_age_approximate).to be_nil
      end
    end

    context 'when age is present and the event is in the past' do
      let(:age) { 40 }
      let(:start_time) { Time.current - 2.years }

      it 'calculates approximate age at the current time based on age at time of effort' do
        expect(subject.current_age_approximate).to eq(42)
      end
    end

    context 'when the event is in the future' do
      let(:age) { 40 }
      let(:start_time) { Time.current + 2.years }

      it 'functions properly' do
        expect(subject.current_age_approximate).to eq(38)
      end
    end
  end

  describe '#total_time_in_aid' do
    subject(:effort) { event.efforts.first }
    let(:event) { build_stubbed(:event_functional, in_sub_splits_only: in_sub_splits_only, efforts_count: 1) }
    let(:in_sub_splits_only) { false }
    let(:split_times) { effort.ordered_split_times }
    let(:time_increment) { 1000 }

    before do
      split_times.each_with_index { |st, i| st.absolute_time = event.start_time + (i * time_increment) }
    end

    context 'when the effort has no split_times' do
      subject(:effort) { build_stubbed(:effort, split_times: []) }

      it 'returns zero' do
        expect(effort.total_time_in_aid).to eq(0)
      end
    end

    context 'when the effort has split_times with only "in" sub_splits' do
      let(:in_sub_splits_only) { true }

      it 'returns zero' do
        expect(effort.total_time_in_aid).to eq(0)
      end
    end

    context 'when the effort has split_times with "in" and "out" sub_splits' do
      it 'correctly calculates time in aid based on times in and out of splits' do
        intermediate_splits_count = event.splits.select(&:intermediate?).size
        expect(effort.total_time_in_aid).to eq(time_increment * intermediate_splits_count)
      end
    end
  end

  describe '#beyond_start?' do
    let(:subject) { build_stubbed(:effort, split_times: split_times) }
    let(:start_split) { build_stubbed(:split, :start) }
    let(:aid_1) { build_stubbed(:split) }
    let(:split_time_1) { build_stubbed(:split_time, lap: 1, split: start_split) }
    let(:split_time_2) { build_stubbed(:split_time, lap: 1, split: aid_1) }
    let(:split_time_3) { build_stubbed(:split_time, lap: 2, split: start_split) }

    context 'when the effort has no split_times' do
      let(:split_times) { [] }

      it 'returns false' do
        expect(subject.beyond_start?).to eq(false)
      end
    end

    context 'when the effort has only a start split_time' do
      let(:split_times) { [split_time_1] }

      it 'returns false' do
        expect(subject.beyond_start?).to eq(false)
      end
    end

    context 'when the effort has a start split_time and an intermediate split_time' do
      let(:split_times) { [split_time_1, split_time_2] }

      it 'returns true' do
        expect(subject.beyond_start?).to eq(true)
      end
    end

    context 'when the effort has no start split_time but has an intermediate split_time' do
      let(:split_times) { [split_time_2] }

      it 'returns true' do
        expect(subject.beyond_start?).to eq(true)
      end
    end

    context 'when the effort has a start split_time for a lap greater than 1' do
      let(:split_times) { [split_time_3] }

      it 'returns true' do
        expect(subject.beyond_start?).to eq(true)
      end
    end
  end

  describe '#finished?' do
    context 'for an event with a fixed lap requirement' do
      let(:laps_required) { 2 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }
      let(:test_splits) { test_event.splits }
      let(:test_split_times) { test_effort.split_times }

      it 'returns true when laps_finished is at least equal to laps_required' do
        effort = test_effort
        split_times = test_effort.split_times
        allow(effort).to receive(:ordered_split_times).and_return(split_times)
        expect(effort.laps_required).to eq(laps_required)
        expect(effort.laps_finished).to eq(laps_required)
        expect(effort.finished?).to eq(true)
      end

      it 'returns false when laps_finished is less than laps_required' do
        effort = test_effort
        split_times = test_effort.split_times[0..-2] # all but the last split_time
        allow(effort).to receive(:ordered_split_times).and_return(split_times)
        expect(effort.laps_required).to eq(laps_required)
        expect(effort.laps_finished).to eq(laps_required - 1)
        expect(effort.finished?).to eq(false)
      end

      it 'returns false when the effort is not started' do
        effort = test_effort
        split_times = []
        allow(effort).to receive(:ordered_split_times).and_return(split_times)
        expect(effort.laps_required).to eq(laps_required)
        expect(effort.laps_finished).to eq(0)
        expect(effort.finished?).to eq(false)
      end
    end

    context 'for an event with unlimited laps' do
      let(:laps_required) { 0 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }
      let(:test_splits) { test_event.splits }
      let(:test_split_times) { test_effort.split_times }

      it 'returns false when no split_time has stopped_here = true' do
        effort = test_effort
        expect(effort.split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.finished?).to eq(false)
      end

      it 'returns true when any split_time has stopped_here = true' do
        effort = test_effort
        effort.split_times.last.stopped_here = true
        expect(effort.finished?).to eq(true)
      end
    end
  end

  describe '#dropped?' do
    context 'for an event with a fixed lap requirement' do
      let(:laps_required) { 1 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }
      let(:test_split_times) { test_effort.split_times }
      let(:incomplete_split_times) { test_split_times.first(2) }

      it 'returns true when a split_time is stopped_here and laps_required are not completed' do
        effort = test_effort
        allow(effort).to receive(:ordered_split_times).and_return(incomplete_split_times)
        incomplete_split_times.last.stopped_here = true
        expect(effort.dropped?).to eq(true)
      end

      it 'returns false when no split_time is stopped_here although laps_required are not completed' do
        effort = test_effort
        allow(effort).to receive(:ordered_split_times).and_return(incomplete_split_times)
        expect(effort.ordered_split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.dropped?).to eq(false)
      end
    end

    context 'for an event with unlimited laps' do
      let(:laps_required) { 0 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }
      let(:test_split_times) { test_effort.split_times }

      it 'returns false always, including when a split_time is stopped_here' do
        effort = test_effort
        effort.split_times.last.stopped_here = true
        expect(effort.dropped?).to eq(false)
      end

      it 'returns false always, including when no split_time is stopped_here' do
        effort = test_effort
        expect(effort.split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.dropped?).to eq(false)
      end
    end
  end

  describe '#stopped?' do
    context 'for an event with a fixed lap requirement' do
      let(:laps_required) { 1 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }
      let(:test_split_times) { test_effort.split_times }
      let(:incomplete_split_times) { test_split_times.first(2) }

      it 'returns true when the effort is finished and the last split_time is stopped_here' do
        effort = test_effort
        effort.split_times.last.stopped_here = true
        expect(effort.stopped?).to eq(true)
      end

      it 'returns true when the effort is finished even if no split_time is stopped_here' do
        effort = test_effort
        split_times = test_effort.split_times
        allow(effort).to receive(:ordered_split_times).and_return(split_times)
        expect(effort.finished?).to eq(true)
        expect(effort.split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.stopped?).to eq(true)
      end

      it 'returns true when the effort is not finished and any split_time is stopped_here' do
        effort = test_effort
        allow(effort).to receive(:ordered_split_times).and_return(incomplete_split_times)
        incomplete_split_times.last.stopped_here = true
        expect(effort.stopped?).to eq(true)
      end

      it 'returns false when the effort is not finished and no split_time is stopped_here' do
        effort = test_effort
        allow(effort).to receive(:ordered_split_times).and_return(incomplete_split_times)
        expect(incomplete_split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.stopped?).to eq(false)
      end
    end

    context 'for an event with unlimited laps' do
      let(:laps_required) { 0 }
      let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
      let(:test_effort) { test_event.efforts.first }

      it 'returns true when any split_time is stopped_here' do
        effort = test_effort
        effort.split_times.last.stopped_here = true
        expect(effort.stopped?).to eq(true)
      end

      it 'returns false when no split_times is stopped_here' do
        effort = test_effort
        expect(effort.split_times.none?(&:stopped_here)).to eq(true)
        expect(effort.stopped?).to eq(false)
      end
    end
  end

  describe '#stopped_split_time' do
    let(:laps_required) { 0 }
    let(:test_event) { build_stubbed(:event_functional, laps_required: laps_required) }
    let(:test_effort) { test_event.efforts.first }

    it 'returns the split_time for which stopped_here is true' do
      effort = test_effort
      split_times = test_effort.split_times
      stopped_indexes = [5]
      expected = split_times[5]
      validate_stopped_split_time(effort, split_times, stopped_indexes, expected)
    end

    it 'returns the last split_time for which stopped_here is true if more than one exists' do
      effort = test_effort
      split_times = test_effort.split_times
      stopped_indexes = [2, 5]
      expected = split_times[5]
      validate_stopped_split_time(effort, split_times, stopped_indexes, expected)
    end

    it 'works properly across laps' do
      effort = test_effort
      split_times = test_effort.split_times
      stopped_indexes = [2, 10]
      expect(split_times[2].lap).not_to eq(split_times[10].lap)
      expected = split_times[10]
      validate_stopped_split_time(effort, split_times, stopped_indexes, expected)
    end

    it 'returns nil if no split_time exists with stopped_here = true' do
      effort = test_effort
      split_times = test_effort.split_times
      stopped_indexes = []
      expected = nil
      validate_stopped_split_time(effort, split_times, stopped_indexes, expected)
    end

    def validate_stopped_split_time(effort, split_times, stopped_indexes, expected)
      stopped_indexes.each { |i| split_times[i].stopped_here = true }
      allow(effort).to receive(:ordered_split_times).and_return(split_times)
      expect(effort.stopped_split_time).to eq(expected)
    end
  end

  describe '#event_start_time_local' do
    subject { build_stubbed(:effort, event: event) }

    context 'when the event has a start_time and a home_time_zone' do
      let(:event) { build_stubbed(:event, start_time: '2017-08-01 12:00:00 GMT', home_time_zone: 'Arizona') }

      it 'returns the start_time in the home_time_zone' do
        expect(subject.event_start_time_local).to be_a(ActiveSupport::TimeWithZone)
        expect(subject.event_start_time_local).to eq('Tue, 01 Aug 2017 05:00:00 MST -07:00')
      end
    end

    context 'when the event has no start_time' do
      let(:event) { build_stubbed(:event, start_time: nil, home_time_zone: 'Arizona') }

      it 'returns nil' do
        expect(subject.event_start_time_local).to be_nil
      end
    end

    context 'when the event has no home_time_zone' do
      let(:event) { build_stubbed(:event, start_time: '2017-08-01 12:00:00 GMT', home_time_zone: nil) }

      it 'returns nil' do
        expect(subject.event_start_time_local).to be_nil
      end
    end
  end

  describe '#concealed?' do
    subject { build_stubbed(:effort, event: event) }

    context 'when the associated event_group is concealed' do
      let(:event) { build_stubbed(:event, event_group: event_group) }
      let(:event_group) { build_stubbed(:event_group, concealed: true) }

      it 'returns true' do
        expect(subject.concealed?).to eq(true)
      end
    end

    context 'when the associated event_group is not concealed' do
      let(:event) { build_stubbed(:event, event_group: event_group) }
      let(:event_group) { build_stubbed(:event_group, concealed: false) }

      it 'returns false' do
        expect(subject.concealed?).to eq(false)
      end
    end
  end

  describe '.concealed and .visible' do
    let(:visible_event_group) { create(:event_group, concealed: false) }
    let(:concealed_event_group) { create(:event_group, concealed: true) }
    let(:visible_event) { create(:event, event_group: visible_event_group) }
    let(:concealed_event) { create(:event, event_group: concealed_event_group) }
    let(:visible_efforts) { create_list(:effort, 2, event: visible_event) }
    let(:concealed_efforts) { create_list(:effort, 2, event: concealed_event) }

    describe '.concealed' do
      it 'limits the subject scope to efforts whose event_group is concealed' do
        visible_efforts.each { |effort| expect(Effort.concealed).not_to include(effort) }
        concealed_efforts.each { |effort| expect(Effort.concealed).to include(effort) }
      end
    end

    describe '.visible' do
      it 'limits the subject scope to efforts whose event_group is visible' do
        visible_efforts.each { |effort| expect(Effort.visible).to include(effort) }
        concealed_efforts.each { |effort| expect(Effort.visible).not_to include(effort) }
      end
    end
  end

  describe '#ordered_split_times' do
    subject { effort.ordered_split_times(lap_split) }
    let(:effort) { build_stubbed(:effort, split_times: split_times) }
    let(:splits) { build_stubbed_list(:split, 3) }
    let(:split_time_1) { build_stubbed(:split_time, lap: 1, split: splits.second, bitkey: in_bitkey) }
    let(:split_time_2) { build_stubbed(:split_time, lap: 1, split: splits.second, bitkey: out_bitkey) }
    let(:split_time_3) { build_stubbed(:split_time, lap: 1, split: splits.third, bitkey: in_bitkey) }
    let(:split_time_4) { build_stubbed(:split_time, lap: 2, split: splits.first, bitkey: in_bitkey) }
    let(:split_times) { [split_time_1, split_time_2, split_time_3, split_time_4].shuffle }

    context 'when called without a lap_split argument' do
      let(:lap_split) { nil }

      it 'returns split_times in the correct order taking into account lap, split, and bitkey' do
        expect(subject).to eq([split_time_1, split_time_2, split_time_3, split_time_4])
      end
    end

    context 'when called without a lap_split argument when imposed_order attributes are present' do
      let(:lap_split) { nil }
      before do
        split_time_1.imposed_order = 4
        split_time_2.imposed_order = 3
        split_time_3.imposed_order = 2
        split_time_4.imposed_order = 1
      end

      it 'returns split_times sorted by imposed_order' do
        expect(subject).to eq([split_time_4, split_time_3, split_time_2, split_time_1])
      end
    end

    context 'when called with a lap_split argument' do
      let(:lap_split) { LapSplit.new(1, splits.second) }

      it 'returns only those split_times that belong to the given lap_split' do
        expect(effort.ordered_split_times(lap_split)).to eq([split_time_1, split_time_2])
      end
    end
  end

  describe '#photo' do
    subject { build(:effort) }
    let(:existing_effort) { build(:effort) }
    let(:file_path) { "#{Rails.root}/spec/fixtures/files/potato3.jpg" }
    let(:photo_file) { File.new(file_path) }

    before do
      existing_effort.update(photo: photo_file)
    end

    it 'copies a photo from an existing effort' do
      expect(existing_effort.photo.exists?).to eq(true)
      subject.update(photo: existing_effort.photo)
      expect(subject.photo.exists?).to eq(true)
    end
  end
end
