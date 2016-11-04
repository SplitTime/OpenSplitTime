require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SplitImporter do

  describe 'initialization' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(name: 'Test Event 2015', course: course, start_time: "2015-07-01 06:00:00") }
    let(:import_file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:current_user_id) { 1 }
    let(:importer) { SplitImporter.new(import_file, event, current_user_id) }

    it 'should set up the headers correctly' do
      expect(importer.header1.size).to eq(15)
      expect(importer.header2.size).to eq(15)
      expect(importer.header1[0]).to eq('first_name')
      expect(importer.header1[7]).to eq('Start')
      expect(importer.header1[13]).to eq('Tunnel Out')
      expect(importer.header2[8]).to eq(6.5)
      expect(importer.header2[11]).to eq(40)
      expect(importer.header2[14]).to eq(51.3)
    end

    describe 'split_import' do
      before do
        importer.split_import
      end

      it 'should import the splits correctly' do
        expect(Split.all.count).to eq(6)
        expect(Split.find_by_base_name('Start').distance_from_start).to eq(0)
        expect(Split.find_by_base_name('Tunnel').distance_from_start).to eq(46.6.miles.to.meters.to_i)
        expect(Split.where(base_name: 'Tunnel').count).to eq(1)
      end

      it 'should correctly set up sub_split_bitmaps for imported splits' do
        expect(Split.find_by_base_name('Start').sub_split_bitmap).to eq(1)
        expect(Split.find_by_base_name('Tunnel').sub_split_bitmap).to eq(65)
      end

      it 'should correctly determine start status' do
        expect(Split.start.count).to eq(1)
        expect(Split.find_by_base_name('Start').kind).to eq('start')
      end

      it 'should correctly determine intermediate status' do
        expect(Split.intermediate.count).to eq(4)
        expect(Split.find_by_base_name('Ridgeline').kind).to eq('intermediate')
      end

      it 'should correctly determine finish status' do
        expect(Split.finish.count).to eq(1)
        expect(Split.find_by_base_name('Finish').kind).to eq('finish')
      end

    end

    describe 'effort_import' do
      let(:effort_importer) { EffortImporter.new(import_file, event, current_user_id) }
      before do
        importer.split_import
        effort_importer.effort_import
      end

      it 'should import all valid efforts and set up names correctly' do
        expect(Effort.all.count).to eq(11)
        expect(Effort.find_by_bib_number(1).first_name).to eq('Fast')
        expect(Effort.find_by_bib_number(1).last_name).to eq('Finisher')
        expect(Effort.find_by_bib_number(143).first_name).to eq('First')
        expect(Effort.find_by_bib_number(143).last_name).to eq('Female')
        expect(Effort.find_by_bib_number(135).first_name).to eq('Local')
        expect(Effort.find_by_bib_number(135).last_name).to eq('Boy')
      end

      it 'should return a failure array containing invalid rows' do
        expect(effort_importer.effort_failure_array.count).to eq(2)
        expect(effort_importer.effort_failure_array.first[0]).to eq('NoLastName')
        expect(effort_importer.effort_failure_array.last[1]).to eq('NoFirstName')
      end

      it 'should correctly assign country codes' do
        expect(Effort.find_by_bib_number(1).country_code).to eq('DE')
        expect(Effort.find_by_bib_number(2).country_code).to eq('US')
        expect(Effort.find_by_bib_number(40).country_code).to eq('GB')
        expect(Effort.find_by_bib_number(32).country_code).to eq('JP')
        expect(Effort.find_by_bib_number(143).country_code).to eq('US')
      end

      it 'should correctly assign states and state codes' do
        expect(Effort.find_by_bib_number(1).state_code).to eq('HH')
        expect(Effort.find_by_bib_number(2).state_code).to eq('TX')
        expect(Effort.find_by_bib_number(143).state_code).to eq('CO')
        expect(Effort.find_by_bib_number(135).state_code).to eq('CO')
      end

      it 'should correctly assign genders' do
        expect(Effort.find_by_bib_number(1).gender).to eq('male')
        expect(Effort.find_by_bib_number(2).gender).to eq('male')
        expect(Effort.find_by_bib_number(143).gender).to eq('female')
        expect(Effort.find_by_bib_number(32).gender).to eq('male')
        expect(Effort.find_by_bib_number(119).gender).to eq('female')
      end

      it 'should correctly determine dropped_split_id' do
        split1 = Split.find_by(base_name: 'Tunnel')
        expect(Effort.find_by_bib_number(49).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by_bib_number(135).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by_bib_number(32).dropped_split_id).to eq(split1.id)
        expect(Effort.find_by_bib_number(1).dropped_split_id).to be_nil
      end

      it 'should correctly set start offsets where start split time != 0' do
        expect(Effort.find_by_bib_number(30).start_offset).to eq(30 * 60)
        expect(Effort.find_by_bib_number(135).start_offset).to eq(60 * 60)
      end

      it 'should set leave start_offset at zero where start split time == 0' do
        expect(Effort.find_by_bib_number(1).start_offset).to eq(0)
        expect(Effort.find_by_bib_number(32).start_offset).to eq(0)
      end

      it 'should reset start split times to zero after updating split_offset' do
        effort1 = Effort.find_by_bib_number(30)
        effort2 = Effort.find_by_bib_number(135)
        split = Split.start.first
        expect(SplitTime.find_by(effort: effort1, split: split).time_from_start).to eq(0)
        expect(SplitTime.find_by(effort: effort2, split: split).time_from_start).to eq(0)
      end

      it 'should import all valid split_times' do
        expect(SplitTime.all.count).to eq(75)
      end

      it 'should correctly set split_time times from start' do
        split1 = Split.find_by_base_name('Ridgeline')
        split2 = Split.find_by_base_name('Mountain Town')
        split3 = Split.find_by_base_name('Tunnel')
        split4 = Split.find_by_base_name('Finish')
        effort1 = Effort.find_by_bib_number(128)
        effort2 = Effort.find_by_bib_number(143)
        effort3 = Effort.find_by_bib_number(186)

        expect(SplitTime.find_by(effort: effort1, split: split1, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 1.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split2, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((22.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split3, sub_split_bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((20.hours + 22.minutes).to_i)
        expect(SplitTime.find_by(effort: effort1, split: split4, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((25.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split1, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 1.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split2, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((23.hours + 39.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split3, sub_split_bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((25.hours + 51.minutes).to_i)
        expect(SplitTime.find_by(effort: effort2, split: split4, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((27.hours + 3.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split1, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((2.hours + 50.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split2, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((37.hours + 45.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split3, sub_split_bitkey: SubSplit::OUT_BITKEY).time_from_start).to eq((41.hours + 24.minutes).to_i)
        expect(SplitTime.find_by(effort: effort3, split: split4, sub_split_bitkey: SubSplit::IN_BITKEY).time_from_start).to eq((43.hours + 58.minutes).to_i)
      end

      it 'should not create a split_time where no time is provided' do
        split1 = Split.find_by(base_name: 'Ridgeline')
        split2 = Split.find_by(base_name: 'Tunnel')
        split3 = Split.find_by(base_name: 'Finish')
        effort1 = Effort.find_by_bib_number(2)
        effort2 = Effort.find_by_bib_number(131)
        effort3 = Effort.find_by_bib_number(49)
        effort4 = Effort.find_by_bib_number(119)

        expect(SplitTime.where(effort: effort1, split: split1).count).to eq(1)
        expect(SplitTime.where(effort: effort2, split: split1, sub_split_bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort2, split: split2, sub_split_bitkey: 64).count).to eq(0)
        expect(SplitTime.where(effort: effort3, split: split3).count).to eq(0)
        expect(SplitTime.where(effort: effort4, split: split1).count).to eq(0)
      end
    end
  end
end
