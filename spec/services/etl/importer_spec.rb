require 'rails_helper'

RSpec.describe ETL::Importer do
  subject { ETL::Importer.new(source_data, data_format, options) }

  context 'when importing efforts using :csv_efforts' do
    let(:source_data) { file_fixture('test_efforts_utf_8.csv') }
    let(:data_format) { :csv_efforts }
    let(:options) { {parent: event, current_user_id: 1} }
    let(:event) { create(:event) }

    it 'creates new efforts within the given event' do
      expect(event.efforts.size).to eq(0)
      subject.import
      expect(subject.errors).to be_empty
      event.reload
      expect(event.efforts.size).to eq(3)
      expect(event.efforts.map(&:first_name)).to match_array(%w(Lucy Charlie Bjorn))
    end
  end

  context 'when importing splits using :csv_splits into a course with no existing splits' do
    let(:source_data) { file_fixture('test_splits.csv') }
    let(:data_format) { :csv_splits }
    let(:options) { {parent: event, current_user_id: 1} }
    let(:event) { create(:event, course: course) }
    let(:course) { create(:course) }

    it 'creates all new splits within the given course' do
      expect(course.splits.size).to eq(0)
      subject.import
      expect(subject.errors).to be_empty
      course.reload
      expect(course.splits.size).to eq(4)
      expect(course.splits.map(&:base_name)).to match_array(['Start', 'Aid 1', 'Aid 2', 'Finish'])
    end
  end

  context 'when importing splits using :csv_splits into a course with existing start and finish splits' do
    let(:source_data) { file_fixture('test_splits.csv') }
    let(:data_format) { :csv_splits }
    let(:options) { {parent: event, current_user_id: 1} }
    let(:event) { create(:event, course: course) }
    let(:course) { create(:course) }
    before do
      create(:split, :start, course: course)
      create(:split, :finish, course: course, distance_from_start: 10_000)
    end

    it 'creates new intermediate splits within the given course' do
      expect(course.splits.size).to eq(2)
      subject.import
      expect(subject.errors).to be_empty
      course.reload
      expect(course.splits.size).to eq(4)
      expect(course.splits.map(&:base_name)).to match_array(['Start', 'Aid 1', 'Aid 2', 'Finish'])
    end
  end

  context 'when importing minimal splits using :csv_splits into a course with existing start and finish splits' do
    let(:source_data) { file_fixture('test_splits_minimal.csv') }
    let(:data_format) { :csv_splits }
    let(:options) { {parent: event, current_user_id: 1} }
    let(:event) { create(:event, course: course) }
    let(:course) { create(:course) }
    before do
      create(:split, :start, base_name: 'Start', course: course)
      create(:split, :finish, base_name: 'Finish', course: course, distance_from_start: 10_000)
    end

    it 'creates new intermediate splits within the given course' do
      expect(course.splits.size).to eq(2)
      subject.import
      expect(subject.errors).to be_empty
      course.reload
      expect(course.splits.size).to eq(4)
      expect(course.splits.map(&:base_name)).to match_array(['Start', 'Aid 1', 'Aid 2', 'Finish'])
    end
  end
end
