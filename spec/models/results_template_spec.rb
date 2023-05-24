# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsTemplate, type: :model do
  it_behaves_like "auditable"

  subject(:results_template) { build(:results_template) }

  describe "#initialize" do
    it "saves a new record to the database" do
      expect(results_template).to be_valid
      expect { results_template.save }.to change { ResultsTemplate.count }.by(1)
    end
  end

  describe "callbacks" do
    subject(:results_template) { build(:results_template, organization: organization, name: name) }
    let(:organization) { nil }
    let(:name) { "Test Template" }

    before { expect(subject).to be_valid }

    context "when organization is nil" do
      it "sets the identifier based on the name" do
        expect(subject.identifier).to eq("test_template")
      end

      it "sets the slug" do
        expect(subject.slug).to eq("test-template")
      end
    end

    context "when organization is present" do
      let(:organization) { organizations(:hardrock) }

      it "sets the identifier based on the name and organization" do
        expect(subject.identifier).to eq("hardrock_test_template")
      end

      it "sets the slug" do
        expect(subject.slug).to eq("hardrock-test-template")
      end
    end
  end
end
