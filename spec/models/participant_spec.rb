require "rails_helper"

# t.string   "first_name"
# t.string   "last_name"
# t.string   "gender"
# t.date     "birthdate"
# t.string   "city"
# t.string   "state"
# t.integer  "country_id"
# t.string   "email"
# t.string   "phone"

RSpec.describe Participant, type: :model do
  it "should be valid when created with a first_name, a last_name, and a gender" do
    participant = Participant.create!(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male')

    expect(Participant.all.count).to eq(1)
    expect(participant.first_name).to eq('Johnny')
    expect(participant.last_name).to eq('Appleseed')
    expect(participant.gender).to eq('male')
    expect(participant).to be_valid
  end

  it "should be invalid without a first_name" do
    participant = Participant.new(first_name: nil, last_name: 'Appleseed', gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:first_name]).to include("can't be blank")
  end

  it "should be invalid without a last_name" do
    participant = Participant.new(first_name: 'Johnny', last_name: nil, gender: 'male')
    expect(participant).not_to be_valid
    expect(participant.errors[:last_name]).to include("can't be blank")
  end

  it "should be invalid without a gender" do
    participant = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: nil)
    expect(participant).not_to be_valid
    expect(participant.errors[:gender]).to include("can't be blank")
  end

  it "should reject invalid country_id" do
    participant = Participant.new(first_name: 'Johnny', last_name: 'Appleseed', gender: 'male', country_id: 1000)
    expect(participant).not_to be_valid
    expect(participant.errors[:country]).to include("can't be blank")
  end

  it "should reject invalid email"
  


end