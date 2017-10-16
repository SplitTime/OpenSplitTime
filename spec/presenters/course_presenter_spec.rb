require 'rails_helper'

RSpec.describe CoursePresenter do
  subject { CoursePresenter.new(course, params, current_user) }
  let(:course) { build_stubbed(:course, splits: splits) }
  let(:params) { ActionController::Parameters.new({}) }
  let(:current_user) { build_stubbed(:admin) }
  let(:splits) { [split_1, split_2] }
  let(:split_1) { build_stubbed(:split) }
  let(:split_2) { build_stubbed(:split) }

  describe '#course' do
    it 'returns the provided course' do
      expect(subject.course).to eq(course)
    end
  end

  describe '#course_has_location_data?' do
    context 'when any split has latitude and longitude information' do
      let(:split_1) { build_stubbed(:split, :with_lat_lon) }

      it 'returns true' do
        expect(subject.course_has_location_data?).to eq(true)
      end
    end

    context 'when no split has latitude and longitude information' do
      it 'returns true' do
        expect(subject.course_has_location_data?).to eq(false)
      end
    end
  end

  describe '#latitude_center' do
    context 'when splits have latitude information' do
      let(:split_1) { build_stubbed(:split, latitude: 40) }
      let(:split_2) { build_stubbed(:split, latitude: 42) }

      it 'returns the average latitude of the splits' do
        expect(subject.latitude_center).to eq(41)
      end
    end

    context 'when splits have no latitude information' do
      it 'returns nil' do
        expect(subject.latitude_center).to be_nil
      end
    end
  end

  describe '#longitude_center' do
    context 'when splits have longitude information' do
      let(:split_1) { build_stubbed(:split, longitude: -100) }
      let(:split_2) { build_stubbed(:split, longitude: -102) }

      it 'returns the average longitude of the splits' do
        expect(subject.longitude_center).to eq(-101)
      end
    end

    context 'when splits have no longitude information' do
      it 'returns nil' do
        expect(subject.longitude_center).to be_nil
      end
    end
  end
end
