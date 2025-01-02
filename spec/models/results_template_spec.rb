require "rails_helper"

RSpec.describe ResultsTemplate, type: :model do
  subject(:results_template) { build(:results_template) }

  describe "#initialize" do
    it "saves a new record to the database" do
      expect(results_template).to be_valid
      expect { results_template.save }.to change { ResultsTemplate.count }.by(1)
    end
  end

  describe "#includes_nonbinary?" do
    let(:result) { results_template.includes_nonbinary? }

    context "when the template includes a nonbinary category" do
      let(:results_template) { results_templates(:masters_and_grandmasters_with_nonbinary) }

      it { expect(result).to eq(true)}
    end

    context "when the template does not include a nonbinary category" do
      let(:results_template) { results_templates(:masters_and_grandmasters) }

      it { expect(result).to eq(false)}
    end
  end
end
