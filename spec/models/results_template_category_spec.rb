# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResultsTemplateCategory do
  subject(:results_template_category) { ResultsTemplateCategory.first }

  describe "#initialize" do
    it "is valid when it has both a results category and a results template" do
      expect(results_template_category).to be_valid
    end
  end

  describe "methods" do
    describe "#category_description" do
      it "returns the description of the associated results_category" do
        expect(results_template_category.category_description).to eq(results_template_category.results_category.description)
      end
    end

    describe "#category_name" do
      it "returns the name of the associated results_category" do
        expect(results_template_category.category_name).to eq(results_template_category.results_category.name)
      end
    end
  end
end
