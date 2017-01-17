require "rails_helper"

# t.string   "name"
# t.string   "description"

RSpec.describe Course, type: :model do
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }

  it "should be valid with a name" do
    course = Course.create!(name: 'Slow Mo 100 CCW')

    expect(Course.all.count).to(equal(1))
    expect(course).to be_valid
  end

  it "should be invalid without a name" do
    course = Course.new(name: nil)
    expect(course).not_to be_valid
    expect(course.errors[:name]).to include("can't be blank")
  end

  it "should not allow duplicate names" do
    Course.create!(name: 'Hard Time 100')
    course = Course.new(name: 'Hard Time 100')
    expect(course).not_to be_valid
    expect(course.errors[:name]).to include("has already been taken")
  end

  describe '#distance' do
    it 'returns a course distance using the distance_from_start of the finish split' do
      course = FactoryGirl.build_stubbed(:course_with_standard_splits)
      splits = course.splits
      finish_split_distance = splits.last.distance_from_start
      expect(finish_split_distance).to be > 0
      allow(course).to receive(:ordered_splits).and_return(splits)
      expect(course.distance).to eq(finish_split_distance)
    end

    it 'returns nil if no finish split exists on the course' do
      course = FactoryGirl.build_stubbed(:course)
      allow(course).to receive(:ordered_splits).and_return([])
      expect(course.distance).to be_nil
    end
  end
end