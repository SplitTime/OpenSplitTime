require 'rails_helper'

# t.string   "name"
# t.string   "description"

RSpec.describe Course, type: :model do
  it_behaves_like 'auditable'
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  it 'is valid with a name' do
    course = Course.create!(name: 'Slow Mo 100 CCW')

    expect(Course.all.count).to(equal(1))
    expect(course).to be_valid
  end

  it 'is invalid without a name' do
    course = Course.new(name: nil)
    expect(course).not_to be_valid
    expect(course.errors[:name]).to include("can't be blank")
  end

  it 'does not allow duplicate names' do
    Course.create!(name: 'Hard Time 100')
    course = Course.new(name: 'Hard Time 100')
    expect(course).not_to be_valid
    expect(course.errors[:name]).to include('has already been taken')
  end

  describe 'methods that produce lap_splits and time_points' do
    let(:course) { FactoryGirl.build_stubbed(:course_with_standard_splits, splits_count: 4) }
    let(:splits) { course.splits }

    describe '#cycled_lap_splits' do
      it 'returns an empty array when called with first(0)' do
        test_course = course
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        lap_splits = test_course.cycled_lap_splits.first(0)
        expect(lap_splits).to eq([])
      end

      it 'returns an enumerator that produces an indeterminate number of ordered LapSplits for the event' do
        test_course = course
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        lap_splits = test_course.cycled_lap_splits.first(10)
        expect(lap_splits.size).to eq(10)
        expect(lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4 + [3] * 2)
        expect(lap_splits.map(&:split).map(&:id)).to eq([101, 102, 103, 104] * 2 + [101, 102])
      end
    end

    describe '#cycled_time_points' do
      it 'returns an empty array when called with first(0)' do
        test_course = course
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        time_points = test_course.cycled_time_points.first(0)
        expect(time_points).to eq([])
      end

      it 'returns an enumerator that produces an indeterminate number of ordered TimePoints for the event' do
        test_course = course
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        time_points = test_course.cycled_time_points.first(12)
        expect(time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
        expect(time_points.map(&:split_id)).to eq([101, 102, 102, 103, 103, 104] * 2)
        expect(time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
      end
    end

    describe '#lap_splits_through' do
      it 'returns an empty array when parameter passed is zero' do
        test_course = course
        lap = 0
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        lap_splits = test_course.lap_splits_through(lap)
        expect(lap_splits).to eq([])
      end

      it 'returns an array whose size is equal to the lap provided * number of splits' do
        test_course = course
        lap = 2
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        lap_splits = test_course.lap_splits_through(lap)
        expect(lap_splits.size).to eq(8)
      end

      it 'returns an array of LapSplit objects ordered by lap, split distance, and bitkey' do
        test_course = course
        lap = 2
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        lap_splits = test_course.lap_splits_through(lap)
        expect(lap_splits.size).to eq(8)
        expect(lap_splits.map(&:lap)).to eq([1] * 4 + [2] * 4)
        expect(lap_splits.map(&:split).map(&:id)).to eq([101, 102, 103, 104] * 2)
      end
    end

    describe '#time_points_through' do
      it 'returns an empty array when parameter passed is zero' do
        test_course = course
        lap = 0
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        time_points = test_course.time_points_through(lap)
        expect(time_points).to eq([])
      end

      it 'returns an array whose size is equal to the lap provided * number of sub_splits' do
        test_course = course
        lap = 2
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        time_points = test_course.time_points_through(lap)
        expect(time_points.size).to eq(12)
      end

      it 'returns an array of TimePoint objects ordered by lap, split distance, and bitkey' do
        test_course = course
        lap = 2
        ordered_splits = splits
        allow(test_course).to receive(:ordered_splits).and_return(ordered_splits)
        time_points = test_course.time_points_through(lap)
        expect(time_points.map(&:lap)).to eq([1] * 6 + [2] * 6)
        expect(time_points.map(&:split_id)).to eq([101, 102, 102, 103, 103, 104] * 2)
        expect(time_points.map(&:bitkey)).to eq([1, 1, 64, 1, 64, 1] * 2)
      end
    end
  end

  describe '#distance' do
    it 'returns a course distance using the distance_from_start of the finish split' do
      course = FactoryGirl.build_stubbed(:course_with_standard_splits)
      course.splits.last.distance_from_start = 200
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.distance).to eq(200)
    end

    it 'returns nil if no finish split exists on the course' do
      course = FactoryGirl.build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.distance).to be_nil
    end
  end

  describe '#vert_gain' do
    it 'returns a course vert_gain using the vert_gain_from_start of the finish split' do
      course = FactoryGirl.build_stubbed(:course_with_standard_splits)
      course.splits.last.vert_gain_from_start = 100
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.vert_gain).to eq(100)
    end

    it 'returns nil if no finish split exists on the course' do
      course = FactoryGirl.build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.vert_gain).to be_nil
    end
  end
  
  describe '#vert_loss' do
    it 'returns a course vert_loss using the vert_loss_from_start of the finish split' do
      course = FactoryGirl.build_stubbed(:course_with_standard_splits)
      course.splits.last.vert_loss_from_start = 50
      allow(course).to receive(:ordered_splits).and_return(course.splits)
      expect(course.vert_loss).to eq(50)
    end

    it 'returns nil if no finish split exists on the course' do
      course = FactoryGirl.build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.vert_loss).to be_nil
    end
  end

  describe '#simple?' do
    subject { course.simple? }
    let(:course) { build_stubbed(:course, splits: splits)}

    context 'when the course has only a start and finish split' do
      let(:splits) { build_stubbed_list(:split, 2) }

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end

    context 'when the course has more than two splits' do
      let(:splits) { build_stubbed_list(:split, 3) }

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end
  end
end
