# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Person, type: :model do
  it_behaves_like 'auditable'
  it_behaves_like 'subscribable'
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }

  describe '#initialize' do
    it 'saves a generic factory-created record to the database' do
      expect { create(:person) }.to change { Person.count }.by(1)
    end

    it 'is valid when created with a first_name, a last_name, and a gender' do
      person = build_stubbed(:person)
      expect(person.first_name).to be_present
      expect(person.last_name).to be_present
      expect(person.gender).to be_present
      expect(person).to be_valid
    end

    it 'is invalid without a first_name' do
      person = build_stubbed(:person, first_name: nil)
      expect(person).not_to be_valid
      expect(person.errors[:first_name]).to include("can't be blank")
    end

    it 'is invalid without a last_name' do
      person = build_stubbed(:person, last_name: nil)
      expect(person).not_to be_valid
      expect(person.errors[:last_name]).to include("can't be blank")
    end

    it 'is invalid without a gender' do
      person = build_stubbed(:person, gender: nil)
      expect(person).not_to be_valid
      expect(person.errors[:gender]).to include("can't be blank")
    end

    it 'rejects invalid email' do
      bad_emails = %w[johnny@appleseed appleseed.com johnny@.com johnny]
      bad_emails.each do |email|
        person = Person.new(email: email)
        expect(person).not_to be_valid
        expect(person.errors[:email]).to include("is invalid")
      end
    end

    it 'permits valid email' do
      person = build_stubbed(:person, email: 'user@example.com')
      expect(person).to be_valid
    end

    it 'rejects implausible birthdates' do
      bad_birthdates = {'1880-01-01' => "can't be before 1900",
                        1.day.from_now => "can't be today or in the future"}
      bad_birthdates.each do |birthdate, error_message|
        person = Person.new(birthdate: birthdate)
        expect(person).not_to be_valid
        expect(person.errors[:birthdate]).to include(error_message)
      end
    end

    it 'permits plausible birthdates' do
      person = build_stubbed(:person, birthdate: '1977-01-01')
      expect(person).to be_valid
    end
  end
end
