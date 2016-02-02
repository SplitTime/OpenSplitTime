require "rails_helper"

RSpec.describe Course, type: :model do
  it "should be valid with a name" do
    course = Course.create!(name: 'Slow Mo 100 CCW')

    expect(Course.all.count).to(equal(1))
    expect(course).to be_valid
  end

  it "should be invalid without a name" do
    course = Course.new(name: nil)
    course.valid?
    expect(course.errors[:name]).to include("can't be blank")
  end

  it "should not allow duplicate names" do
    Course.create!(name: 'Hard Time 100')
    course = Course.new(name: 'Hard Time 100')
    course.valid?
    expect(course.errors[:name]).to include("has already been taken")
  end

end