require 'rails_helper'

RSpec.describe SplitImporter do
  describe 'split_import' do
    let(:course) { create(:course) }
    let(:event) { create(:event, course: course, start_time: '2015-07-01 06:00:00') }
    let(:import_file) { 'spec/fixtures/files/baddata2015test.xlsx' }
    let(:current_user_id) { 1 }
    let(:split_importer) { SplitImporter.new(file_path: import_file, event: event, current_user_id: current_user_id) }

    before do
      split_importer.split_import
    end

    # Tests have been compressed into a single test with many 'expects' to speed run time

    it 'imports the splits correctly' do
      expect(Split.all.count).to eq(6)
      expect(Split.find_by(base_name: 'Start').distance_from_start).to eq(0)
      expect(Split.find_by(base_name: 'Tunnel').distance_from_start).to eq(46.6.miles.to.meters.to_i)
      expect(Split.where(base_name: 'Tunnel').count).to eq(1)
    # end

    # it 'correctly sets up sub_split_bitmaps for imported splits' do
      expect(Split.find_by(base_name: 'Start').sub_split_bitmap).to eq(1)
      expect(Split.find_by(base_name: 'Tunnel').sub_split_bitmap).to eq(65)
    # end

    # it 'correctly determines start status' do
      expect(Split.start.count).to eq(1)
      expect(Split.find_by(base_name: 'Start').kind).to eq('start')
    # end

    # it 'correctly determines intermediate status' do
      expect(Split.intermediate.count).to eq(4)
      expect(Split.find_by(base_name: 'Ridgeline').kind).to eq('intermediate')
    # end

    # it 'correctly determines finish status' do
      expect(Split.finish.count).to eq(1)
      expect(Split.find_by(base_name: 'Finish').kind).to eq('finish')
    end
  end
end
