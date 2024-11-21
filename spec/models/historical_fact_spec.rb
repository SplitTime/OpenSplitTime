# frozen_string_literal: true

require "rails_helper"

RSpec.describe HistoricalFact, type: :model do
  it_behaves_like "auditable"
  it_behaves_like "matchable"
  it_behaves_like "state_country_syncable"

  it { is_expected.to capitalize_attribute(:first_name) }
  it { is_expected.to capitalize_attribute(:last_name) }
  it { is_expected.to capitalize_attribute(:city) }
  it { is_expected.to strip_attribute(:first_name).collapse_spaces }
  it { is_expected.to strip_attribute(:last_name).collapse_spaces }
  it { is_expected.to strip_attribute(:address).collapse_spaces }
  it { is_expected.to strip_attribute(:city).collapse_spaces }
  it { is_expected.to strip_attribute(:state_code).collapse_spaces }
  it { is_expected.to strip_attribute(:country_code).collapse_spaces }
  it { is_expected.to strip_attribute(:comments).collapse_spaces }

  describe "callbacks" do
    subject { build(:historical_fact) }

    it "creates a personal_info_hash when a new record is created" do
      expect(subject.personal_info_hash).to be_nil
      subject.save!
      expect(subject.personal_info_hash).not_to be_nil
    end

    it "updates the personal_info_hash when an existing record is updated" do
      subject.save!
      subject.first_name = subject.first_name + "(updated)"
      expect { subject.save! }.to change { subject.personal_info_hash }
    end
  end
end
