# frozen_string_literal: true

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
end
