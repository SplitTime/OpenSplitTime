require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe SplitImporter do

  describe 'initialization' do
    let(:course) { Course.create!(name: 'Test Course 100') }
    let(:event) { Event.create!(name: 'Test Event 2015', course: course, start_time: "2015-07-01 06:00:00", laps_required: 1) }
    let(:import_file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:current_user_id) { 1 }
    let(:split_importer) { SplitImporter.new(file_path: import_file, event: event, current_user_id: current_user_id) }

    describe 'split_import' do
      before do
        split_importer.split_import
      end

      it 'should import the splits correctly' do
        expect(Split.all.count).to eq(6)
        expect(Split.find_by(base_name: 'Start').distance_from_start).to eq(0)
        expect(Split.find_by(base_name: 'Tunnel').distance_from_start).to eq(46.6.miles.to.meters.to_i)
        expect(Split.where(base_name: 'Tunnel').count).to eq(1)
      end

      it 'should correctly set up sub_split_bitmaps for imported splits' do
        expect(Split.find_by(base_name: 'Start').sub_split_bitmap).to eq(1)
        expect(Split.find_by(base_name: 'Tunnel').sub_split_bitmap).to eq(65)
      end

      it 'should correctly determine start status' do
        expect(Split.start.count).to eq(1)
        expect(Split.find_by(base_name: 'Start').kind).to eq('start')
      end

      it 'should correctly determine intermediate status' do
        expect(Split.intermediate.count).to eq(4)
        expect(Split.find_by(base_name: 'Ridgeline').kind).to eq('intermediate')
      end

      it 'should correctly determine finish status' do
        expect(Split.finish.count).to eq(1)
        expect(Split.find_by(base_name: 'Finish').kind).to eq('finish')
      end
    end
  end
end