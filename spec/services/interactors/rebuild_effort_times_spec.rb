# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe Interactors::RebuildEffortTimes do
  subject { described_class.new(effort: effort, current_user_id: current_user_id) }
  let(:effort) { efforts(:rufa_2017_12h_progress_lap2) }
  let(:current_user_id) { 1 }
  let(:ordered_split_times) { effort.ordered_split_times }
  let(:ordered_split_ids) { effort.event.ordered_splits.map(&:id) }
  let(:id_1) { ordered_split_ids.first }
  let(:id_2) { ordered_split_ids.second }
  let(:id_3) { ordered_split_ids.third }

  describe '#initialize' do
    context 'when effort and current_user_id arguments are provided' do
      it 'initializes' do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#perform!' do
    context 'when raw_times exist and split_times are in incorrect order' do
      let(:disordered_absolute_times) { ['2017-02-11 14:00:10',
                                         '2017-02-11 19:33:20',
                                         '2017-02-11 19:50:00',
                                         '2017-02-11 16:05:43',
                                         '2017-02-11 17:25:36',
                                         '2017-02-11 18:13:54'] }
      before do
        disordered_absolute_times.each_with_index do |time, i|
          ordered_split_times[i].update(absolute_time: time)
        end

        ordered_split_times[1..-1].map do |st|
          RawTime.create!(event_group: effort.event_group, bib_number: effort.bib_number, split_name: st.split.base_name,
                          absolute_time: st.absolute_time, bitkey: st.bitkey, source: 'rebuild_effort_test')
        end
      end

      it 'preserves the existing starting absolute time' do
        subject.perform!
        expect(effort.ordered_split_times.first.absolute_time).to eq('2017-02-11 14:00:10')
      end

      context 'when raw_times are not duplicated' do
        it 'reorders the split_times, retaining sub_split integrity' do
          old_split_times = ordered_split_times.dup
          response = subject.perform!
          expect(response).to be_successful
          expect(effort.ordered_split_times.map(&:absolute_time)).to eq(disordered_absolute_times.sort)
          expect(effort.ordered_split_times.map(&:sub_split)).to match_array(old_split_times.map(&:sub_split))
          expect(effort.ordered_split_times.map(&:lap)).to eq([1, 2, 2, 2, 3, 3])
          expect(effort.ordered_split_times.map(&:split_id)).to eq([id_1, id_1, id_2, id_3, id_2, id_3])
        end

        it 'matches raw_times with the newly created split_times' do
          subject.perform!
          raw_times = RawTime.where(source: 'rebuild_effort_test')
          expect(effort.ordered_split_times[1..-1].map(&:id)).to eq(raw_times.sort_by(&:absolute_time).map(&:split_time_id))
        end

        it 'sets data status for the effort and all split times' do
          subject.perform!
          expect(effort.data_status).to eq('bad')
          expect(effort.ordered_split_times.map(&:data_status)).to eq(%w(good good good good good bad))
        end
      end

      context 'when raw_times are duplicated' do
        before do
          st = ordered_split_times[3]
          duplicate_time = st.absolute_time + 1.minute
          earlier_creation_time = st.created_at - 1.minute
          RawTime.create!(event_group: effort.event_group, bib_number: effort.bib_number, split_name: st.split.base_name,
                          absolute_time: duplicate_time, bitkey: st.bitkey, source: 'rebuild_effort_test',
                          created_at: earlier_creation_time)
        end

        it 'reorders the split_times, retaining sub_split integrity and skipping the duplicate time' do
          old_split_times = ordered_split_times.dup
          response = subject.perform!
          expect(response).to be_successful
          expect(effort.ordered_split_times.map(&:absolute_time)).to eq(disordered_absolute_times.sort)
          expect(effort.ordered_split_times.map(&:sub_split)).to match_array(old_split_times.map(&:sub_split))
          expect(effort.ordered_split_times.map(&:lap)).to eq([1, 2, 2, 2, 3, 3])
          expect(effort.ordered_split_times.map(&:split_id)).to eq([id_1, id_1, id_2, id_3, id_2, id_3])
        end

        it 'matches raw_times with the newly created split_times' do
          subject.perform!
          raw_times = RawTime.where(source: 'rebuild_effort_test')
          expect(raw_times.pluck(:split_time_id)).to all be_present
          expect(raw_times.pluck(:split_time_id)).to match_array(effort.ordered_split_times[1..-1].map(&:id) + [effort.ordered_split_times[1].id])
        end
      end
      
      context 'when raw_times are disassociated' do
        let(:disassociated_raw_time) { RawTime.where(source: 'rebuild_effort_test', absolute_time: disassociated_time) }
        let(:disassociated_time) { '2017-02-11 16:05:43' }
        before { disassociated_raw_time.update(disassociated_from_effort: true) }
        
        it 'ignores the disassociated raw time' do
          subject.perform!
          expect(effort.ordered_split_times.size).to eq(disordered_absolute_times.size - 1)
          expected_absolute_times = disordered_absolute_times.sort - [disassociated_time]
          expect(effort.ordered_split_times.map(&:absolute_time)).to eq(expected_absolute_times)
        end
      end

      context 'when raw_times have no absolute_time' do
        before do
          st = ordered_split_times[3]
          RawTime.create!(event_group: effort.event_group, bib_number: effort.bib_number, split_name: st.split.base_name,
                          entered_time: '10:10:10', absolute_time: nil, bitkey: st.bitkey, source: 'ignored')
        end

        it 'reorders the split_times, retaining sub_split integrity and ignoring the time that lacks an absolute_time' do
          old_split_times = ordered_split_times.dup
          response = subject.perform!
          expect(response).to be_successful
          expect(effort.ordered_split_times.map(&:absolute_time)).to eq(disordered_absolute_times.sort)
          expect(effort.ordered_split_times.map(&:sub_split)).to match_array(old_split_times.map(&:sub_split))
          expect(effort.ordered_split_times.map(&:lap)).to eq([1, 2, 2, 2, 3, 3])
          expect(effort.ordered_split_times.map(&:split_id)).to eq([id_1, id_1, id_2, id_3, id_2, id_3])
        end

        it 'matches raw_times with the newly created split_times' do
          subject.perform!
          raw_times = RawTime.where(source: 'rebuild_effort_test')
          expect(effort.ordered_split_times[1..-1].map(&:id)).to eq(raw_times.sort_by(&:absolute_time).map(&:split_time_id))
        end
      end
    end
  end
end
