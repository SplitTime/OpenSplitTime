require "rails_helper"

RSpec.describe User, type: :model do

  it "should create a valid user with name and email and password" do
    user_attr = FactoryGirl.attributes_for(:user)
    user = User.create!(user_attr)
    # user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')

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

  describe 'connections' do
    it 'should allow a single connection with a person' do
      user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')
      person = Person.create!(first_name: 'Sir', last_name: 'Mixalot', gender: 'male')

      user.interests << person
      expect(user.interests.count).to eq(1)
    end

    it 'should allow two connections with people' do
      user = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at@gmail.com', password: 'imahuman')
      person1 = Person.create!(first_name: 'Sir', last_name: 'Mixalot', gender: 'male')
      person2 = Person.create!(first_name: 'Curious', last_name: 'George', gender: 'male')

      user.interests << person1
      user.interests << person2
      expect(user.interests.count).to eq(2)
      expect(person1)
    end

    it 'should allow multiple users to create connections with a person' do
      user1 = User.create!(first_name: 'Alan', last_name: 'Turing', email: 'at1@gmail.com', password: 'imahuman')
      user2 = User.create!(first_name: 'Mindy', last_name: 'Turing', email: 'at2@gmail.com', password: 'imahuman')
      user3 = User.create!(first_name: 'Alan', last_name: 'Greenspan', email: 'at3@gmail.com', password: 'imahuman')
      person = Person.create!(first_name: 'Curious', last_name: 'George', gender: 'male')

      user1.interests << person
      user2.interests << person
      user3.interests << person
      expect(user1.interests.count).to eq(1)
      expect(user2.interests.count).to eq(1)
      expect(user3.interests.count).to eq(1)
      expect(person.followers.count).to eq(3)
    end

  end

end