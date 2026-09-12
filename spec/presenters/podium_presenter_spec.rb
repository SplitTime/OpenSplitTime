require "rails_helper"

RSpec.describe PodiumPresenter do
  subject { described_class.new(event, view_context, template: template) }

  let(:event) { events(:hardrock_2014) }
  let(:view_context) { double(prepared_params: prepared_params) }
  let(:prepared_params) { PreparedParams.new(ActionController::Parameters.new(sort: sort_param), [], ["best_performance"]) }
  let(:template) { ResultsTemplate.new(name: "Test Template", aggregation_method: :inclusive, categories: categories) }

  def build_category(name, performance:, fixed_position: false, **attributes)
    category = ResultsCategory.new(name: name, fixed_position: fixed_position, **attributes)
    category.efforts = [Effort.new(overall_performance: performance)]
    category
  end

  describe "#sorted_categories" do
    let(:overall_men) { build_category("Overall Men", male: true, fixed_position: true, performance: "1000") }
    let(:overall_women) { build_category("Overall Women", female: true, fixed_position: true, performance: "1111") }
    let(:men_20s) { build_category("20 to 29 Men", male: true, low_age: 20, high_age: 29, performance: "0110") }
    let(:men_30s) { build_category("30 to 39 Men", male: true, low_age: 30, high_age: 39, performance: "0100") }
    let(:men_40_up) { build_category("40 and Up Men", male: true, low_age: 40, performance: "0010") }
    let(:women_20s) { build_category("20 to 29 Women", female: true, low_age: 20, high_age: 29, performance: "0111") }
    let(:women_30s) { build_category("30 to 39 Women", female: true, low_age: 30, high_age: 39, performance: "0011") }
    let(:women_40_up) { build_category("40 and Up Women", female: true, low_age: 40, performance: "0001") }

    let(:result_names) { subject.sorted_categories.map(&:name) }

    context "when sorting by category" do
      let(:sort_param) { "category" }
      let(:categories) { [overall_men, overall_women, men_20s, women_20s, men_30s, women_30s] }

      it "returns the categories in template order" do
        expect(result_names).to eq(categories.map(&:name))
      end
    end

    context "when sorting by best performance" do
      let(:sort_param) { "best_performance" }

      context "when male and female floating categories are evenly matched" do
        let(:categories) { [overall_men, overall_women, men_20s, women_20s, men_30s, women_30s] }

        it "places fixed categories first, then pairs floating categories by rank and sorts each pair" do
          expect(result_names).to eq(["Overall Women", "Overall Men", "20 to 29 Women", "20 to 29 Men", "30 to 39 Men", "30 to 39 Women"])
        end
      end

      context "when there are more male than female floating categories" do
        let(:categories) { [overall_men, overall_women, men_20s, men_30s, men_40_up, women_20s] }

        it "includes every category without raising" do
          expect(result_names).to eq(["Overall Women", "Overall Men", "20 to 29 Women", "20 to 29 Men", "30 to 39 Men", "40 and Up Men"])
        end
      end

      context "when there are more female than male floating categories" do
        let(:categories) { [overall_men, overall_women, men_20s, women_20s, women_30s, women_40_up] }

        it "includes every category without raising" do
          expect(result_names).to eq(["Overall Women", "Overall Men", "20 to 29 Women", "20 to 29 Men", "30 to 39 Women", "40 and Up Women"])
        end
      end
    end
  end
end
