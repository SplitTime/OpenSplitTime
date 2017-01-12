require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SplitImporter do

  describe 'initialization' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(name: 'Test Event 2015', course: course, start_time: "2015-07-01 06:00:00", laps_required: 1) }
    let(:import_file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:current_user_id) { 1 }
    let(:split_importer) { SplitImporter.new(file_path: import_file, event: event, current_user_id: current_user_id) }

    describe 'effort_import' do
      let(:effort_importer) { EffortImporter.new(file_path: import_file, event: event, current_user_id: current_user_id, without_status: true) }
      before do
        split_importer.split_import
        effort_importer.effort_import
      end

      it 'imports all valid efforts, sets up data correctly, and returns a failure array containing invalid rows' do
        effort1 = Effort.find_by(bib_number: 1)
        effort2 = Effort.find_by(bib_number: 143)
        effort3 = Effort.find_by(bib_number: 135)
        expect(Effort.all.count).to eq(11)
        expect(effort1.first_name).to eq('Fast')
        expect(effort1.last_name).to eq('Finisher')
        expect(effort1.gender).to eq('male')
        expect(effort1.country_code).to eq('DE')
        expect(effort1.state_code).to eq('HH')
        expect(effort1.age).to eq(28)
        expect(effort1.birthdate).to eq(Date.new(1987,2,1))
        expect(effort2.first_name).to eq('First')
        expect(effort2.last_name).to eq('Female')
        expect(effort2.gender).to eq('female')
        expect(effort2.country_code).to eq('US')
        expect(effort2.state_code).to eq('CO')
        expect(effort2.age).to eq(25)
        expect(effort2.birthdate).to be_nil
        expect(effort3.first_name).to eq('Local')
        expect(effort3.last_name).to eq('Boy')
        expect(effort3.gender).to eq('male')
        expect(effort3.country_code).to eq('US')
        expect(effort3.state_code).to eq('CO')
        expect(effort3.age).to be_nil
        expect(effort3.birthdate).to be_nil
        expect(effort_importer.effort_failure_array.count).to eq(2)
        expect(effort_importer.effort_failure_array.first[0]).to eq('NoLastName')
        expect(effort_importer.effort_failure_array.last[1]).to eq('NoFirstName')
      end

      it 'correctly determines dropped_split_ids and sets start_offsets' do
        split1 = Split.find_by(base_name: 'Tunnel')
        expect(Effort.find_by(bib_number: 49).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by(bib_number: 135).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by(bib_number: 32).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by(bib_number: 1).dropped_split_id).to be_nil
        expect(Effort.find_by(bib_number: 30).start_offset).to eq(30 * 60)
        expect(Effort.find_by(bib_number: 135).start_offset).to eq(60 * 60)
        expect(Effort.find_by(bib_number: 1).start_offset).to eq(0)
        expect(Effort.find_by(bib_number: 32).start_offset).to eq(0)
      end

      it 'imports all valid split_times and correctly sets split_time times from start' do
        split1 = Split.find_by(base_name: 'Ridgeline')
        split2 = Split.find_by(base_name: 'Mountain Top')
        split3 = Split.find_by(base_name: 'Tunnel')
        split4 = Split.find_by(base_name: 'Finish')
        effort1 = Effort.find_by(bib_number: 128)
        effort2 = Effort.find_by(bib_number: 143)
        effort3 = Effort.find_by(bib_number: 186)

        expect(SplitTime.all.count).to eq(75)
        expect(SplitTime.find_by(effort: effort1, split: split2, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((22.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split3, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((20.hours + 22.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split4, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((25.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split1, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 10.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split2, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((23.hours + 39.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split3, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((25.hours + 51.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split4, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((27.hours + 3.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split1, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 50.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split2, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((37.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split3, bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((41.hours + 24.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split4, bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((43.hours + 58.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split1, bitkey: SubSplit::IN_BITKEY).time_from_start).to be_within(1.second).of((2.hours + 1.minutes).to_i)
      end

      it 'does not create a split_time where no time is provided' do
        split1 = Split.find_by(base_name: 'Ridgeline')
        split2 = Split.find_by(base_name: 'Tunnel')
        split3 = Split.find_by(base_name: 'Finish')
        effort1 = Effort.find_by(bib_number: 2)
        effort2 = Effort.find_by(bib_number: 131)
        effort3 = Effort.find_by(bib_number: 49)
        effort4 = Effort.find_by(bib_number: 119)

        expect(SplitTime.where(effort: effort1, split: split1).count).to eq(1)
        expect(SplitTime.where(effort: effort2, split: split1, bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort2, split: split2, bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort3, split: split3).count).to eq(0)
        expect(SplitTime.where(effort: effort4, split: split1).count).to eq(0)
      end
    end
  end
end