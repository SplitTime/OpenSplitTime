# frozen_string_literal: true

require 'rails_helper'

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
        expect { create(:effort) }.to change { Effort.count }.by (1)
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
        effort = build_stubbed(:effort, without_slug: true, event: nil)
        allow(effort).to receive(:finished?)
        expect(effort).not_to be_valid
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
      let(:existing_event_group) { event_groups(:sum) }
      let(:event_1) { existing_event_group.events.first }
      let(:event_2) { existing_event_group.events.second }
      let(:existing_effort) { Effort.where(event: event_1).where.not(person: nil).first }

      it 'does not permit more than one effort by a person in a given event' do
        effort = build_stubbed(:effort, event: event_1, person: existing_effort.person)
        expect(effort).not_to be_valid
        expect(effort.errors[:person]).to include(/has already been entered in/)
      end

      it 'does not permit more than one effort by a person in a given event_group' do
        effort = build_stubbed(:effort, event: event_2, person: existing_effort.person)
        expect(effort).not_to be_valid
        expect(effort.errors[:person]).to include(/has already been entered in/)
      end

      it 'permits more than one effort in a given event with unassigned people' do
        effort = build_stubbed(:effort, split_times: [], event: event_1, person: nil)
        expect(effort).to be_valid
      end

      it 'permits more than one effort in a given event with different people' do
        effort = build_stubbed(:effort, event: event_1, person: build_stubbed(:person))
        expect(effort).to be_valid
      end

      it 'does not permit duplicate bib_numbers within a given event' do
        effort = build_stubbed(:effort, event: event_1, bib_number: existing_effort.bib_number)
        expect(effort).not_to be_valid
        expect(effort.errors[:bib_number]).to include(/already exists/)
      end

      it 'does not permit duplicate bib_numbers within a given event_group' do
        effort = build_stubbed(:effort, event: event_2, bib_number: existing_effort.bib_number)
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
    context 'when the effort has no split_times' do
      let(:effort) { efforts(:hardrock_2014_not_started) }

      it 'returns zero' do
        expect(effort.total_time_in_aid).to eq(0)
      end
    end

    context 'when the effort has split_times with only "in" sub_splits' do
      let(:effort) { efforts(:ggd30_50k_finished_first) }

      it 'returns zero' do
        expect(effort.total_time_in_aid).to eq(0)
      end
    end

    context 'when the effort has split_times with "in" and "out" sub_splits' do
      let(:effort) { efforts(:hardrock_2014_finished_first) }

      it 'correctly calculates time in aid based on times in and out of splits' do
        expect(effort.total_time_in_aid).to eq(24.minutes)
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
      context 'when laps_finished is at least equal to laps_required' do
        let(:effort) { efforts(:hardrock_2014_finished_first) }

        it 'returns true' do
          expect(effort.finished?).to eq(true)
        end
      end

      context 'when laps_finished is less than laps_required and effort is dropped' do
        let(:effort) { efforts(:hardrock_2014_drop_ouray) }

        it 'returns false' do
          expect(effort.finished?).to eq(false)
        end
      end

      context 'when laps_finished is less than laps_required and effort is in progress' do
        let(:effort) { efforts(:hardrock_2016_progress_sherman) }

        it 'returns false' do
          expect(effort.finished?).to eq(false)
        end
      end

      context 'when the effort is not started' do
        let(:effort) { efforts(:hardrock_2014_not_started) }

        it 'returns false' do
          expect(effort.finished?).to eq(false)
        end
      end
    end

    context 'for an event with unlimited laps' do
      context 'when no when no split_time has stopped_here: true' do
        let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }

        it 'returns false' do
          expect(effort.finished?).to eq(false)
        end
      end

      context 'when any split_time has stopped_here == true' do
        let(:effort) { efforts(:rufa_2017_24h_finished_first) }

        it 'returns true' do
          expect(effort.finished?).to eq(true)
        end
      end
    end
  end

  describe '#dropped?' do
    context 'for an event with a fixed lap requirement' do
      context 'when a split_time is stopped_here and laps_required are not completed' do
        let(:effort) { efforts(:hardrock_2014_drop_ouray) }

        it 'returns true' do
          expect(effort.dropped?).to eq(true)
        end
      end

      context 'when no split_time is stopped_here although laps_required are not completed' do
        let(:effort) { efforts(:hardrock_2016_progress_sherman) }

        it 'returns false' do
          expect(effort.dropped?).to eq(false)
        end
      end
    end

    context 'for an event with unlimited laps' do
      context 'always, including when a split_time is stopped_here' do
        let(:effort) { efforts(:rufa_2017_24h_finished_first) }

        it 'returns false' do
          expect(effort.dropped?).to eq(false)
        end
      end

      context 'always, including when no split_time is stopped_here' do
        let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }

        it 'returns false' do
          expect(effort.dropped?).to eq(false)
        end
      end
    end
  end

  describe '#stopped?' do
    context 'for an event with a fixed lap requirement' do
      context 'when the effort is finished and the last split_time is stopped_here' do
        let(:effort) { efforts(:hardrock_2014_finished_with_stop) }

        it 'returns true' do
          expect(effort.stopped?).to eq(true)
        end
      end

      context 'when the effort is finished even if no split_time is stopped_here' do
        let(:effort) { efforts(:hardrock_2014_finished_without_stop) }

        it 'returns true' do
          expect(effort.stopped?).to eq(true)
        end
      end

      context 'when the effort is not finished and any split_time is stopped_here' do
        let(:effort) { efforts(:hardrock_2014_drop_ouray) }

        it 'returns true' do
          expect(effort.stopped?).to eq(true)
        end
      end

      context 'when the effort is not finished and no split_time is stopped_here' do
        let(:effort) { efforts(:hardrock_2016_progress_sherman) }

        it 'returns false' do
          expect(effort.stopped?).to eq(false)
        end
      end
    end

    context 'for an event with unlimited laps' do
      context 'when any split_time is stopped_here' do
        let(:effort) { efforts(:rufa_2017_24h_finished_first) }

        it 'returns true' do
          expect(effort.stopped?).to eq(true)
        end
      end

      context 'when no split_time is stopped_here' do
        let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }

        it 'returns false' do
          expect(effort.stopped?).to eq(false)
        end
      end
    end
  end

  describe '#stopped_split_time' do
    context 'when one split_time has stopped_here: true' do
      let(:effort) { efforts(:hardrock_2014_drop_ouray) }
      let(:expected) { split_times(:hardrock_2014_drop_ouray_ouray_out_1) }

      it 'returns the split_time for which stopped_here is true' do
        expect(effort.stopped_split_time).to eq(expected)
      end
    end

    context 'if more than one exists' do
      let(:effort) { efforts(:hardrock_2014_multiple_stops) }
      let(:expected) { split_times(:hardrock_2014_multiple_stops_grouse_out_1) }

      it 'returns the last split_time for which stopped_here is true' do
        expect(effort.stopped_split_time).to eq(expected)
      end
    end

    context 'when multiple stops exist across laps' do
      let(:effort) { efforts(:rufa_2017_24h_multiple_stops) }
      let(:expected) { split_times(:rufa_2017_24h_multiple_stops_finish_3) }

      it 'works properly' do
        expect(effort.stopped_split_time).to eq(expected)
      end
    end

    context 'if no split_time exists with stopped_here: true' do
      let(:effort) { efforts(:rufa_2017_24h_progress_lap6) }

      it 'returns nil' do
        expect(effort.stopped_split_time).to be_nil
      end
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
    let(:concealed_event_group) { event_groups(:dirty_30) }
    let(:visible_efforts) { Effort.joins(:event).where.not(events: {event_group_id: concealed_event_group.id}).first(5) }
    let(:concealed_efforts) { Effort.joins(:event).where(events: {event_group_id: concealed_event_group.id}).first(5) }

    before { concealed_event_group.update(concealed: true) }

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

  describe '#generate_new_topic_resource?' do
    subject(:effort) { efforts(:sum_100k_un_started) }
    before { effort.assign_attributes(scheduled_start_time: scheduled_start_time) }

    context 'when the calculated start time is long ago' do
      let(:scheduled_start_time) { 1.year.ago }

      it 'returns false' do
        expect(effort.send(:generate_new_topic_resource?)).to eq(false)
      end
    end

    context 'when the calculated start time is less than a day ago' do
      let(:scheduled_start_time) { 12.hours.ago }

      it 'returns true' do
        expect(effort.send(:generate_new_topic_resource?)).to eq(true)
      end
    end

    context 'when the calculated start time is in the future' do
      let(:scheduled_start_time) { 12.hours.from_now }

      it 'returns true' do
        expect(effort.send(:generate_new_topic_resource?)).to eq(true)
      end
    end

    context 'when the effort is finished' do
      let(:scheduled_start_time) { 12.hours.ago }
      before { allow(effort).to receive(:finished?).and_return(true) }

      it 'returns false' do
        expect(effort.send(:generate_new_topic_resource?)).to eq(false)
      end
    end
  end
end
