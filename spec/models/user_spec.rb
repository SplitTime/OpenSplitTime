require "rails_helper"

RSpec.describe User, type: :model do
  it "should create a valid user with name and email and password" do
    user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')

    expect(User.all.count).to(equal(1))
    expect(user).to be_valid
  end

  it "should be invalid without a last name" do
    user = User.new(first_name: 'Elvis', email: 'elvis@gmail.com', password: 'hounddog')
    expect(user.valid?).to be_falsey
  end

  it "should be invalid without an email" do
    user = User.new(first_name: 'Alan', last_name: 'Turing', password: 'imahuman')
    expect(user.valid?).to be_falsey
  end

  describe 'friendships' do
    it 'should allow a single friendship with a participant' do
      user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')
      participant = Participant.create!(first_name: 'Sir', last_name: 'Mixalot', gender: 'male')

      user.participants << participant
      expect(user.participants.count).to eq(1)
    end

    it 'should allow two friendships with participants' do
      user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')
      participant1 = Participant.create!(first_name: 'Sir', last_name: 'Mixalot', gender: 'male')
      participant2 = Participant.create!(first_name: 'Curious', last_name: 'George', gender: 'male')

      user.participants << participant1
      user.participants << participant2
      expect(user.participants.count).to eq(2)
      expect(participant1)
    end

    it 'should allow multiple users to create friendships with a participant' do
      user1 = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at1@gmail.com', password: 'imahuman')
      user2 = User.create!(first_name: 'Mindy', last_name: 'Turing', email: 'at2@gmail.com', password: 'imahuman')
      user3 = User.create!(first_name: 'Alan', last_name: 'Greenspan', email: 'at3@gmail.com', password: 'imahuman')
      participant = Participant.create!(first_name: 'Curious', last_name: 'George', gender: 'male')

      user1.participants << participant
      user2.participants << participant
      user3.participants << participant
      expect(user1.participants.count).to eq(1)
      expect(user2.participants.count).to eq(1)
      expect(user3.participants.count).to eq(1)
      expect(participant.users.count).to eq(3)
    end

  end

end