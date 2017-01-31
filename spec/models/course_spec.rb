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
end