# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'creates a valid user with name and email and password' do
    user_attr = FactoryBot.attributes_for(:user)
    user = User.create!(user_attr)

    expect(User.all.size).to(equal(1))
    expect(user).to be_valid
  end

  it 'is invalid without a last name' do
    user = build_stubbed(:user, last_name: nil)
    expect(user.valid?).to be_falsey
  end

  it 'is invalid without an email' do
    user = build_stubbed(:user, email: nil)
    expect(user.valid?).to be_falsey
  end

  describe '#subscriptions' do
    it 'allows a single subscription with a person' do
      user = create(:user)
      person = create(:person)

      user.interests << person
      expect(user.interests.size).to eq(1)
    end

    it 'allows two connections with people' do
      user = create(:user)
      people = create_list(:person, 2)

      people.each { |person| user.interests << person }
      expect(user.interests.size).to eq(2)
      people.each { |person| expect(user.interests).to include(person) }
    end

    it 'allows multiple users to create connections with a person' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user)
      person = create(:person)

      user1.interests << person
      user2.interests << person
      user3.interests << person
      expect(user1.interests.size).to eq(1)
      expect(user2.interests.size).to eq(1)
      expect(user3.interests.size).to eq(1)
      expect(person.followers.size).to eq(3)
    end
  end

  describe '#steward_of?' do
    subject { build_stubbed(:user) }
    let(:organization) { build_stubbed(:organization, stewards: stewards) }
    let(:event_group) { build_stubbed(:event_group, organization: organization) }
    let(:event) { build_stubbed(:event, event_group: event_group) }
    let(:effort) { build_stubbed(:effort, event: event) }

    context 'when the user is a steward' do
      let(:stewards) { [subject] }

      context 'when the provided resource is an Organization' do
        it 'returns true' do
          expect(subject.steward_of?(organization)).to eq(true)
        end
      end

      context 'when the provided resource is an EventGroup' do
        it 'returns true' do
          expect(subject.steward_of?(event_group)).to eq(true)
        end
      end

      context 'when the provided resource is an Event' do
        it 'returns true' do
          expect(subject.steward_of?(event)).to eq(true)
        end
      end

      context 'when the provided resource is an Effort' do
        it 'returns true' do
          expect(subject.steward_of?(effort)).to eq(true)
        end
      end
    end

    context 'when the user is not a steward' do
      let(:stewards) { [] }

      context 'when the provided resource is an Organization' do
        it 'returns false' do
          expect(subject.steward_of?(organization)).to eq(false)
        end
      end

      context 'when the provided resource is an EventGroup' do
        it 'returns false' do
          expect(subject.steward_of?(event_group)).to eq(false)
        end
      end

      context 'when the provided resource is an Event' do
        it 'returns false' do
          expect(subject.steward_of?(event)).to eq(false)
        end
      end

      context 'when the provided resource is an Effort' do
        it 'returns false' do
          expect(subject.steward_of?(effort)).to eq(false)
        end
      end
    end

    context 'when the provided resource does not implement :stewards' do
      let(:split_time) { build_stubbed(:split_time, effort: effort) }
      let(:stewards) { [subject] }

      it 'returns false' do
        expect(subject.steward_of?(split_time)).to eq(false)
      end
    end
  end
end
