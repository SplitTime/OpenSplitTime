# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RawTime, type: :model do
  it_behaves_like 'auditable'
  it_behaves_like 'time_recordable'

  describe '.with_relation_ids' do
    let(:event_1) { events(:sum_100k) }
    let(:event_2) { events(:sum_55k) }
    let(:event_1_efforts) { event_1.efforts.first(2) }
    let(:event_2_efforts) { event_2.efforts.first(2) }
    let(:event_group) { event_groups(:sum) }
    let(:course_1_split) { event_1.ordered_splits.second }
    let(:course_2_split) { event_2.ordered_splits.second }

    context 'when bib_numbers and split_names are valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.first.bib_number, split_name: course_1_split.base_name) }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.second.bib_number, split_name: course_1_split.base_name) }
      let!(:raw_time_3) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.first.bib_number, split_name: course_2_split.base_name) }
      let!(:raw_time_4) { create(:raw_time, event_group: event_group, bib_number: event_2_efforts.second.bib_number, split_name: course_2_split.base_name) }

      it 'returns raw_times with effort_id, split_id, and event_id attributes loaded' do
        raw_times = RawTime.where(id: [raw_time_1, raw_time_2, raw_time_3, raw_time_4]).with_relation_ids
        efforts = event_1_efforts + event_2_efforts
        expect(raw_times.map(&:effort_id)).to match_array(efforts.map(&:id))
        expect(raw_times.map(&:split_id)).to match_array([course_1_split.id, course_1_split.id, course_2_split.id, course_2_split.id])
        expect(raw_times.map(&:event_id)).to match_array([event_1.id, event_1.id, event_2.id, event_2.id])
      end
    end

    context 'when split_name is valid and bib_number is valid but has one or more 0s on the front' do
      let(:bib_number_1) { "0#{event_1_efforts.first.bib_number}"}
      let(:bib_number_2) { "00#{event_1_efforts.second.bib_number}"}
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: bib_number_1, split_name: course_1_split.base_name) }
      let!(:raw_time_2) { create(:raw_time, event_group: event_group, bib_number: bib_number_2, split_name: course_1_split.base_name) }

      it 'returns raw_times with correct effort_ids associated' do
        raw_times = RawTime.where(id: [raw_time_1, raw_time_2]).with_relation_ids
        efforts = event_1_efforts
        expect(raw_times.map(&:effort_id)).to match_array(efforts.map(&:id))
      end
    end

    context 'when split_name is valid but bib_number is not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '9999', split_name: course_1_split.base_name) }

      it 'returns raw_time with effort_id, split_id, and event_id attributes set to nil' do
        expect(raw_time_1.effort_id).to be_nil
        expect(raw_time_1.event_id).to be_nil
        expect(raw_time_1.split_id).to be_nil
      end
    end

    context 'when bib_number is valid but split_name is not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: event_1_efforts.first.bib_number, split_name: 'Nonexistent') }

      it 'returns raw_time with effort_id and event_id attributes loaded and split_id set to nil' do
        expect(raw_time_1.effort_id).to eq(event_1_efforts.first.id)
        expect(raw_time_1.event_id).to eq(event_1.id)
        expect(raw_time_1.split_id).to be_nil
      end
    end

    context 'when bib_number and split_name split_name are both not valid' do
      let!(:raw_time_1) { create(:raw_time, event_group: event_group, bib_number: '9999', split_name: 'Nonexistent') }

      it 'returns raw_time with effort_id, split_id, and event_id attributes set to nil' do
        expect(raw_time_1.effort_id).to be_nil
        expect(raw_time_1.event_id).to be_nil
        expect(raw_time_1.split_id).to be_nil
      end
    end
  end

  describe '#split_time' do
    let(:event) { events(:sum_100k) }
    let(:effort) { event.efforts.first }
    let(:event_group) { event_groups(:sum) }
    let(:split) { event.ordered_splits.second }
    let(:split_time) { effort.ordered_split_times.second}

    it 'when related split_time is deleted, sets raw_time.split_time to nil' do
      raw_time = create(:raw_time, event_group: event_group, split_name: split.parameterized_base_name, split_time: split_time)
      expect(raw_time.split_time).to eq(split_time)
      split_time.destroy
      raw_time.reload
      expect(raw_time.split_time).to be_nil
    end
  end

  describe '#military_time' do
    subject { raw_time.military_time(time_zone) }

    let(:raw_time) { RawTime.new(entered_time: entered_time, absolute_time: absolute_time) }
    let(:entered_time) { nil }
    let(:absolute_time) { nil }
    let(:time_zone) { nil }

    context 'when absolute_time is present and time_zone is passed in' do
      let(:absolute_time) { '2018-10-31 08:00:00'.in_time_zone('Arizona') }
      let(:time_zone) { 'Arizona' }

      it 'returns the hh:mm:ss component as a string' do
        expect(subject).to eq('08:00:00')
      end
    end

    context 'when absolute_time is not present but entered_time is present' do
      let(:entered_time) { '08:00:00' }

      it 'returns the entered_time as a string' do
        expect(subject).to eq('08:00:00')
      end
    end

    context 'when entered_time has hours and minutes but has no seconds' do
      let(:entered_time) { '08:00' }

      it 'returns the entered_time as a string with imputed :00 seconds' do
        expect(subject).to eq('08:00:00')
      end
    end

    context 'when entered_time has text where it should have zeros' do
      let(:entered_time) { '08:mm:ss' }

      it 'returns the entered_time as a string with imputed :00 minutes and seconds' do
        expect(subject).to eq('08:00:00')
      end
    end
  end

  describe '#data_status' do
    subject { RawTime.new }

    it 'acts as an ActiveRecord enum' do
      expect(subject.data_status).to be_nil

      subject.assign_attributes(data_status: :bad)
      expect(subject.data_status).to eq('bad')
      expect(subject).to be_bad
      expect(subject).not_to be_good

      subject.assign_attributes(data_status: :good)
      expect(subject.data_status).to eq('good')
      expect(subject).to be_good
      expect(subject).not_to be_bad
    end
  end

  describe '#clean?' do
    subject { RawTime.new(data_status: data_status, split_time_exists: split_time_exists) }
    let(:data_status) { nil }
    let(:split_time_exists) { false }

    context 'when data_status is good and split_time_exists is false' do
      let(:data_status) { :good }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when data_status is questionable and split_time_exists is false' do
      let(:data_status) { :questionable }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when data_status is bad and split_time_exists is false' do
      let(:data_status) { :bad }

      it 'returns false' do
        expect(subject.clean?).to eq(false)
      end
    end

    context 'when data_status is nil and split_time_exists is false' do
      let(:data_status) { nil }

      it 'returns true' do
        expect(subject.clean?).to eq(true)
      end
    end

    context 'when split_time_exists is true regardless of data_status' do
      let(:data_status) { :good }
      let(:split_time_exists) { true }

      it 'returns false' do
        expect(subject.clean?).to eq(false)
      end
    end
  end

  describe '#has_time_data?' do
    subject { RawTime.new(absolute_time: absolute_time, entered_time: entered_time) }

    context 'when absolute_time is nil' do
      let(:absolute_time) { nil }

      context 'when entered_time exists' do
        let(:entered_time) { '12:12:12' }

        it 'returns true' do
          expect(subject.has_time_data?).to eq(true)
        end
      end

      context 'when entered_time is an empty string' do
        let(:entered_time) { '' }

        it 'returns false' do
          expect(subject.has_time_data?).to eq(false)
        end
      end

      context 'when entered_time is nil' do
        let(:entered_time) { nil }

        it 'returns false' do
          expect(subject.has_time_data?).to eq(false)
        end
      end
    end

    context 'when entered_time is nil' do
      let(:entered_time) { nil }

      context 'when absolute_time exists' do
        let(:absolute_time) { '12:12:12' }

        it 'returns true' do
          expect(subject.has_time_data?).to eq(true)
        end
      end

      context 'when absolute_time is an empty string' do
        let(:absolute_time) { '' }

        it 'returns false' do
          expect(subject.has_time_data?).to eq(false)
        end
      end

      context 'when absolute_time is nil' do
        let(:absolute_time) { nil }

        it 'returns false' do
          expect(subject.has_time_data?).to eq(false)
        end
      end
    end

    context 'when neither entered_time nor absolute_time is nil' do
      let(:entered_time) { '12:12:12' }
      let(:absolute_time) { '2018-10-01 12:12:12 -0600' }

      it 'returns true' do
        expect(subject.has_time_data?).to eq(true)
      end
    end
  end
end
