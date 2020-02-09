# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'creates a valid user with name and email and password' do
    user_attr = FactoryBot.attributes_for(:user)
    user = User.create!(user_attr)

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

  describe '#normalize_phone' do
    subject(:user) { build(:user, phone: phone) }
    let(:normalized_phone) { '+12025551212' }

    context 'when phone is a standard US or Canada number with +1 prefix' do
      let(:phone) { '+12025551212' }

      it 'does not change phone and user is valid' do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context 'when phone is a standard US or Canada number with 1 prefix' do
      let(:phone) { '12025551212' }

      it 'normalizes phone number and user is valid' do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context 'when phone is a standard US or Canada number without + or 1 prefix' do
      let(:phone) { '2025551212' }

      it 'normalizes phone number and user is valid' do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context 'when phone is a standard US or Canada number with +1 prefix and parentheses, spaces, and dashes' do
      let(:phone) { '+1 (202) 555-1212' }

      it 'normalizes phone number and user is valid' do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context 'when phone is a standard US or Canada number with parentheses, spaces, and dashes' do
      let(:phone) { '(202) 555-1212' }

      it 'normalizes phone number and user is valid' do
        user.validate
        expect(user.phone).to eq(normalized_phone)
        expect(user).to be_valid
      end
    end

    context 'when phone is a nonstandard number' do
      let(:phone) { '555-1212' }

      it 'attempts to normalize phone number and user is not valid' do
        user.validate
        expect(user.phone).to eq('5551212')
        expect(user).not_to be_valid
      end
    end

    context 'when phone is nonsensical' do
      let(:phone) { 'hello234' }

      it 'attempts to normalize phone number and user is not valid' do
        user.validate
        expect(user.phone).to eq('234')
        expect(user).not_to be_valid
      end
    end

    context 'when phone contains no numeric data' do
      let(:phone) { 'hello' }

      it 'eliminates the data and user is valid' do
        user.validate
        expect(user.phone).to be_nil
        expect(user).to be_valid
      end
    end
  end

  describe '#interests' do
    let(:user_1) { users(:third_user) }
    let(:subject_people) { people.first(2) }
    let(:person) { subject_people.first }

    context 'when adding a single interest' do
      it 'works as expected' do
        expect(user_1.interests.size).to eq(0)
        user_1.interests << person
        expect(user_1.interests.size).to eq(1)
        expect(user_1.interests.first).to eq(person)
      end
    end

    context 'when adding multiple interests' do
      it 'works as expected' do
        expect(user_1.interests.size).to eq(0)
        user_1.interests << subject_people
        expect(user_1.interests.size).to eq(2)
        expect(user_1.interests).to match_array(subject_people)
      end
    end

    context 'when multiple users have interest in the same person' do
      let(:user_2) { users(:fourth_user) }

      it 'works as expected' do
        expect(user_1.interests.size).to eq(0)
        expect(user_2.interests.size).to eq(0)
        expect(person.followers.size).to eq(0)

        user_1.interests << person
        user_2.interests << person
        person.reload

        expect(user_1.interests.size).to eq(1)
        expect(user_2.interests.size).to eq(1)
        expect(person.followers.size).to eq(2)

        expect(user_1.interests).to eq([person])
        expect(user_2.interests).to eq([person])
        expect(person.followers).to match_array([user_1, user_2])
      end
    end
  end

  describe '#watch_efforts' do
    let(:user_1) { users(:third_user) }
    let(:subject_efforts) { efforts.first(2) }
    let(:effort) { subject_efforts.first }
    let(:topic_resource_key) { '123' }

    before do
      subject_efforts.each do |effort|
        allow(effort).to receive(:topic_resource_key).and_return(topic_resource_key)
      end
    end

    context 'when adding a single watch_effort that has a topic_resource_key' do

      it 'adds the watch_effort' do
        expect(user_1.watch_efforts.size).to eq(0)
        user_1.watch_efforts << effort
        expect(user_1.watch_efforts.size).to eq(1)
        expect(user_1.watch_efforts.first).to eq(effort)
      end
    end

    context 'when adding a watch_effort that has no topic_resource_key' do
      let(:topic_resource_key) { nil }

      it 'does not add the watch_effort and returns an error' do
        expect(user_1.watch_efforts.size).to eq(0)
        expect { user_1.watch_efforts << effort }.to raise_error(/Resource key can't be blank/)
        expect(user_1.watch_efforts.size).to eq(0)
      end
    end

    context 'when adding multiple watch_efforts with topic_resource_keys' do

      it 'works as expected' do
        expect(user_1.watch_efforts.size).to eq(0)
        user_1.watch_efforts << subject_efforts
        expect(user_1.watch_efforts.size).to eq(2)
        expect(user_1.watch_efforts).to match_array(subject_efforts)
      end
    end

    context 'when multiple users are watching the same effort' do
      let(:user_2) { users(:fourth_user) }

      it 'works as expected' do
        expect(user_1.watch_efforts.size).to eq(0)
        expect(user_2.watch_efforts.size).to eq(0)
        expect(effort.followers.size).to eq(0)

        user_1.watch_efforts << effort
        user_2.watch_efforts << effort
        effort.reload

        expect(user_1.watch_efforts.size).to eq(1)
        expect(user_2.watch_efforts.size).to eq(1)
        expect(effort.followers.size).to eq(2)

        expect(user_1.watch_efforts).to eq([effort])
        expect(user_2.watch_efforts).to eq([effort])
        expect(effort.followers).to match_array([user_1, user_2])
      end
    end
  end

  describe '#steward_of?' do
    subject { build_stubbed(:user) }
    let(:organization) { build_stubbed(:organization, stewards: stewards) }
    let(:event_group) { build_stubbed(:event_group, organization: organization) }
    let(:event) { build_stubbed(:event, event_group: event_group) }
    let(:effort) { build_stubbed(:effort, event: event) }
    let(:split_time) { build_stubbed(:split_time, effort: effort) }

    context 'when the user is a steward' do
      let(:stewards) { [subject] }

      [:organization, :event_group, :event, :effort, :split_time].each do |resource|
        context "when the provided resource is a/an #{resource}" do
          it 'returns true' do
            expect(subject.steward_of?(send(resource))).to eq(true)
          end
        end
      end
    end

    context 'when the user is not a steward' do
      let(:stewards) { [] }

      [:organization, :event_group, :event, :effort, :split_time].each do |resource|
        context "when the provided resource is a/an #{resource}" do
          it 'returns false' do
            expect(subject.steward_of?(send(resource))).to eq(false)
          end
        end
      end
    end

    context 'when the provided resource does not implement :stewards' do
      let(:user) { build_stubbed(:user) }

      it 'returns false' do
        expect(subject.steward_of?(user)).to eq(false)
      end
    end
  end
end
