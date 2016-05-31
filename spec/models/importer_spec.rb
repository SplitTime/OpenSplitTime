require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe Importer do

  describe 'initialization' do
    before do
      @course = Course.create!(name: 'Test Course 100')
      @event = Event.create!(name: 'Test Event 2015', course: @course, start_time: "2015-07-01 06:00:00")
      @file = fixture_file_upload('spec/fixtures/files/baddata2015test.xlsx', extension: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      @importer = Importer.new(@file, @event, 1)
    end

    it 'should create an instance of Importer' do
      expect(@importer).to exist
    end

    it 'should set up the headers correctly' do
      expect(@importer.header1.size).to eq(15)
      expect(@importer.header2.size).to eq(15)
      expect(@importer.header1[0]).to eq('first_name')
      expect(@importer.header1[7]).to eq('Start')
      expect(@importer.header1[13]).to eq('Tunnel Out')
      expect(@importer.header2[8]).to eq(12.2)
      expect(@importer.header2[11]).to eq(40)
      expect(@importer.header2[14]).to eq(51.3)
    end
  end

  describe 'split_import' do
    before do
      @importer.split_import
    end

    it 'should import the splits correctly' do
      expect(Split.all.count).to eq(6)
      expect(Split.where(name: 'Start').first.distance_from_start).to eq(0)
      expect(Split.where(name: 'Tunnel').first.distance_from_start).to eq(46.6.miles.to.meters)
      expect(Split.where(name: 'Tunnel').count).to eq(1)
    end

    it 'should correctly set up sub_split_bitmaps for imported splits' do
      expect(Split.where(name: 'Start').first.sub_split_bitmap).to eq(1)
      expect(Split.where(name: 'Tunnel').first.sub_split_bitmap).to eq(65)
    end

    it 'should correctly determine start status' do
      expect(Split.start.count).to eq(1)
      expect(Split.where(name: 'Start').first.kind).to eq('start')
    end

    it 'should correctly determine intermediate status' do
      expect(Split.intermediate.count).to eq(4)
      expect(Split.where(name: 'Ridgeline').first.kind).to eq('intermediate')
    end

    it 'should correctly determine finish status' do
      expect(Split.finish.count).to eq(1)
      expect(Split.where(name: 'Finish').first.kind).to eq('Finish')
    end

  end

  describe 'effort_import' do
    before do
      @importer.split_import
      @importer.effort_import
    end

    it 'should import all valid efforts and set up names correctly' do
      expect(Effort.all.count).to eq(11)
      expect(Effort.where(bib_number: 1).first.first_name).to eq('Fast')
      expect(Effort.where(bib_number: 1).first.last_name).to eq('Finisher')
      expect(Effort.where(bib_number: 143).first.first_name).to eq('First')
      expect(Effort.where(bib_number: 143).first.last_name).to eq('Female')
      expect(Effort.where(bib_number: 135).first.first_name).to eq('Hour')
      expect(Effort.where(bib_number: 135).first.last_name).to eq('Offset')
    end

    it 'should return a failure array containing invalid rows' do
      expect(@importer.effort_failure_array.count).to eq(2)
      expect(@importer.effort_failure_array.first).to eq('NoLastName')
      expect(@importer.effort_failure_array.last).to eq('NoFirstName')
    end

    it 'should correctly assign country codes' do
      expect(Effort.where(bib_number: 1).first.country_code).to eq('DE')
      expect(Effort.where(bib_number: 2).first.country_code).to eq('US')
      expect(Effort.where(bib_number: 45).first.country_code).to eq('GB')
      expect(Effort.where(bib_number: 32).first.country_code).to eq('JP')
      expect(Effort.where(bib_number: 143).first.country_code).to eq('US')
    end

    it 'should correctly assign states and state codes' do
      expect(Effort.where(bib_number: 1).first.state_code).to eq('Bavaria')
      expect(Effort.where(bib_number: 2).first.state_code).to eq('TX')
      expect(Effort.where(bib_number: 143).first.state_code).to eq('CO')
      expect(Effort.where(bib_number: 135).first.state_code).to eq('CO')
    end

    it 'should correctly assign genders' do
      expect(Effort.where(bib_number: 1).first.gender).to eq('male')
      expect(Effort.where(bib_number: 2).first.gender).to eq('male')
      expect(Effort.where(bib_number: 45).first.gender).to eq('female')
      expect(Effort.where(bib_number: 62).first.gender).to eq('male')
      expect(Effort.where(bib_number: 119).first.gender).to eq('female')
    end

    it 'should correctly determine dropped_split_id' do
      split1 = Split.where(name: 'Tunnel').first
      split2 = Split.where(name: 'Mountain Town').first
      expect(Effort.where(bib_number: 131).first.dropped_split_id).to eq(split1.id)
      expect(Effort.where(bib_number: 49).first.dropped_split_id).to eq(split1.id)
      expect(Effort.where(bib_number: 135).first.dropped_split_id).to eq(split2.id)
      expect(Effort.where(bib_number: 32).first.dropped_split_id).to eq(split2.id)
      expect(Effort.where(bib_number: 1).first.dropped_split_id).to be_nil
    end

    it 'should correctly set start offsets where start split time != 0' do
      expect(Effort.where(bib_number: 30).first.start_offset).to eq(30 * 60)
      expect(Effort.where(bib_number: 135).first.start_offset).to eq(60 * 60)
    end

    it 'should set leave start_offset at zero where start split time == 0' do
      expect(Effort.where(bib_number: 1).first.start_offset).to eq(0)
      expect(Effort.where(bib_number: 32).first.start_offset).to eq(0)
    end

    it 'should reset start split times to zero after updating split_offset' do
      effort1 = Effort.where(bib_number: 30).first
      effort2 = Effort.where(bib_number: 135).first
      split = Split.start.first
      expect(SplitTime.where(effort: effort1, split: split).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split).first.time_from_start).to eq(0)
    end

    it 'should import all valid split_times' do
      expect(SplitTime.all.count).to eq(81)
    end

    it 'should correctly set split_time times from start' do
      split1 = Split.where(name: 'Ridgeline').first
      split2 = Split.where(name: 'Mountain Town').first
      split3 = Split.where(name: 'Tunnel').first
      split4 = Split.where(name: 'Finish').first
      effort1 = Effort.where(bib_number: 128).first
      effort2 = Effort.where(bib_number: 143).first
      effort3 = Effort.where(bib_number: 186).first

      expect(SplitTime.where(effort: effort1, split: split1, sub_split_bitkey: 64).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort1, split: split2, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort1, split: split3, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort1, split: split4, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split1, sub_split_bitkey: 64).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split2, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split3, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split4, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort3, split: split1, sub_split_bitkey: 64).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort3, split: split2, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort3, split: split3, sub_split_bitkey: 1).first.time_from_start).to eq(0)
      expect(SplitTime.where(effort: effort3, split: split4, sub_split_bitkey: 1).first.time_from_start).to eq(0)
    end

    it 'should not create a split_time where no time is provided' do
      split1 = Split.where(name: 'Ridgeline').first
      split2 = Split.where(name: 'Tunnel').first
      split3 = Split.where(name: 'Finish').first
      effort1 = Effort.where(bib_number: 2).first
      effort2 = Effort.where(bib_number: 131).first
      effort3 = Effort.where(bib_number: 49).first
      effort4 = Effort.where(bib_number: 119).first

      expect(SplitTime.where(effort: effort1, split: split1).count).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split1, sub_split_bitkey: 64).count).to eq(0)
      expect(SplitTime.where(effort: effort2, split: split2, sub_split_bitkey: 64).count).to eq(0)
      expect(SplitTime.where(effort: effort3, split: split3).count).to eq(0)
      expect(SplitTime.where(effort: effort4, split: split1).count).to eq(0)
    end
  end

end
