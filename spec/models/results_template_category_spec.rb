require "rails_helper"

RSpec.describe ResultsTemplateCategory do
  subject(:template_category) { ResultsTemplateCategory.first }

  describe "#initialize" do
    it "is valid when it has both a results category and a results template" do
      expect(template_category).to be_valid
    end
  end

  describe "#create" do
    let!(:new_rtc) { ResultsTemplateCategory.create!(category: ResultsCategory.first, template: ResultsTemplate.first) }

    it "is valid when it has both a results category and a results template" do
      expect(new_rtc).to be_valid
      expect(new_rtc.category).to eq(ResultsCategory.first)
      expect(new_rtc.template).to eq(ResultsTemplate.first)
      expect(new_rtc.position).to be_present
    end
  end

  describe "methods" do
    describe "#category_description" do
      it "returns the description of the associated results_category" do
        expect(template_category.category_description).to eq(template_category.category.description)
      end
    end

    describe "#category_name" do
      it "returns the name of the associated results_category" do
        expect(template_category.category_name).to eq(template_category.category.name)
      end
    end
  end
end
