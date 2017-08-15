require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe EffortImporter do
  describe 'initialization' do
    let(:course) { create(:course) }
    let(:event) { create(:event, course: course, start_time: '2015-07-01 06:00:00') }
    let(:import_file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:current_user_id) { 1 }
    let(:split_importer) { SplitImporter.new(file_path: import_file, event: event, current_user_id: current_user_id) }

    describe 'effort_import' do
      let(:effort_1) { Effort.find_by(bib_number: 1) }
      let(:effort_2) { Effort.find_by(bib_number: 2) }
      let(:effort_11) { Effort.find_by(bib_number: 11) }
      let(:effort_30) { Effort.find_by(bib_number: 30) }
      let(:effort_32) { Effort.find_by(bib_number: 32) }
      let(:effort_49) { Effort.find_by(bib_number: 49) }
      let(:effort_119) { Effort.find_by(bib_number: 119) }
      let(:effort_128) { Effort.find_by(bib_number: 128) }
      let(:effort_131) { Effort.find_by(bib_number: 131) }
      let(:effort_135) { Effort.find_by(bib_number: 135) }
      let(:effort_143) { Effort.find_by(bib_number: 143) }
      let(:effort_186) { Effort.find_by(bib_number: 186) }
      
      let(:split_start) { Split.find_by(base_name: 'Start') }
      let(:split_ridgeline) { Split.find_by(base_name: 'Ridgeline') }
      let(:split_mountain) { Split.find_by(base_name: 'Mountain Top') }
      let(:split_tunnel) { Split.find_by(base_name: 'Tunnel') }
      let(:split_finish) { Split.find_by(base_name: 'Finish') }


      let(:effort_importer) { EffortImporter.new(file_path: import_file, event: event, current_user_id: current_user_id, with_status: false) }
      before do
        split_importer.split_import
        effort_importer.effort_import
      end

      # Tests have been compressed into a single test with many 'expects' to speed run time
      # (each test takes about 1 second to run)

      it 'imports all valid efforts, sets up data correctly, and returns a failure array containing invalid rows' do
        expect(Effort.all.count).to eq(12)
        expect(effort_1.first_name).to eq('Fast')
        expect(effort_1.last_name).to eq('Finisher')
        expect(effort_1.gender).to eq('male')
        expect(effort_1.country_code).to eq('DE')
        expect(effort_1.state_code).to eq('HH')
        expect(effort_1.age).to eq(28)
        expect(effort_1.birthdate).to eq(Date.new(1987, 2, 1))
        expect(effort_143.first_name).to eq('First')
        expect(effort_143.last_name).to eq('Female')
        expect(effort_143.gender).to eq('female')
        expect(effort_143.country_code).to eq('US')
        expect(effort_143.state_code).to eq('CO')
        expect(effort_143.age).to eq(25)
        expect(effort_143.birthdate).to be_nil
        expect(effort_135.first_name).to eq('Local')
        expect(effort_135.last_name).to eq('Boy')
        expect(effort_135.gender).to eq('male')
        expect(effort_135.country_code).to eq('US')
        expect(effort_135.state_code).to eq('CO')
        expect(effort_135.age).to be_nil
        expect(effort_135.birthdate).to be_nil
        expect(effort_importer.effort_failure_array.count).to eq(2)
        expect(effort_importer.effort_failure_array.first[:data]).to include('NoLastName')
        expect(effort_importer.effort_failure_array.last[:data]).to include('NoFirstName')
        expect(effort_importer.effort_failure_array.first[:errors]).to include(/Last name can't be blank/)
        expect(effort_importer.effort_failure_array.last[:errors]).to include(/First name can't be blank/)
      # end

      # it 'correctly sets start_offsets, including where start split is omitted' do
        expect(effort_135.start_offset).to eq(60 * 60)
        expect(effort_32.start_offset).to eq(0)
        expect(effort_1.start_offset).to eq(0)
        expect(effort_30.start_offset).to eq(30 * 60)
        expect(effort_11.start_offset).to eq(0)
      # end

      # it 'imports all valid split_times and correctly sets split_time times from start' do
        expect(SplitTime.all.count).to eq(78)
        expect(SplitTime.find_by(effort: effort_128, split: split_mountain, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((22.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_128, split: split_tunnel, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((20.hours + 22.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_128, split: split_finish, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((25.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_143, split: split_ridgeline, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 10.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_143, split: split_mountain, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((23.hours + 39.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_143, split: split_tunnel, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((25.hours + 51.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_143, split: split_finish, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((27.hours + 3.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_186, split: split_ridgeline, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 50.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_186, split: split_mountain, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((37.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_186, split: split_tunnel, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((41.hours + 24.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_186, split: split_finish, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((43.hours + 58.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_128, split: split_ridgeline, bitkey: SubSplit::IN_BITKEY).time_from_start).to be_within(1.second).of((2.hours + 1.minutes).to_i)
        expect(SplitTime.find_by(effort: effort_11, split: split_start, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq(0)
      # end

      # it 'does not create a split_time where no time is provided and creates no split_times for an empty effort' do
        expect(SplitTime.where(effort: effort_2, split: split_ridgeline).count).to eq(1)
        expect(SplitTime.where(effort: effort_131, split: split_ridgeline, bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort_131, split: split_tunnel, bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort_49, split: split_finish).count).to eq(0)
        expect(effort_119.split_times.count).to eq(0)
      end
    end
  end
end
