# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Results::Compute do
  describe '.perform' do
    subject { Results::Compute.perform(efforts: efforts, template: template).map { |category| category.efforts.map(&:id) } }
    let(:template) { ResultsTemplate.new(categories: categories, podium_size: podium_size, aggregation_method: aggregation_method) }

    let(:male_1) { instance_double('Effort', id: 101, overall_rank: 1, template_age: 20, gender: 'male') }
    let(:male_2) { instance_double('Effort', id: 102, overall_rank: 3, template_age: 30, gender: 'male') }
    let(:male_3) { instance_double('Effort', id: 103, overall_rank: 5, template_age: 20, gender: 'male') }
    let(:male_4) { instance_double('Effort', id: 104, overall_rank: 7, template_age: 40, gender: 'male') }
    let(:male_5) { instance_double('Effort', id: 105, overall_rank: 9, template_age: 10, gender: 'male') }
    let(:male_6) { instance_double('Effort', id: 106, overall_rank: 11, template_age: 30, gender: 'male') }
    let(:male_7) { instance_double('Effort', id: 107, overall_rank: 13, template_age: 40, gender: 'male') }
    let(:male_8) { instance_double('Effort', id: 108, overall_rank: 15, template_age: 40, gender: 'male') }
    let(:male_9) { instance_double('Effort', id: 109, overall_rank: 17, template_age: 20, gender: 'male') }
    let(:male_10) { instance_double('Effort', id: 110, overall_rank: 19, template_age: 30, gender: 'male') }
    let(:female_1) { instance_double('Effort', id: 201, overall_rank: 2, template_age: 20, gender: 'female') }
    let(:female_2) { instance_double('Effort', id: 202, overall_rank: 4, template_age: 30, gender: 'female') }
    let(:female_3) { instance_double('Effort', id: 203, overall_rank: 6, template_age: 20, gender: 'female') }
    let(:female_4) { instance_double('Effort', id: 204, overall_rank: 8, template_age: 40, gender: 'female') }
    let(:female_5) { instance_double('Effort', id: 205, overall_rank: 10, template_age: 10, gender: 'female') }
    let(:female_6) { instance_double('Effort', id: 206, overall_rank: 12, template_age: 30, gender: 'female') }
    let(:female_7) { instance_double('Effort', id: 207, overall_rank: 14, template_age: 40, gender: 'female') }
    let(:female_8) { instance_double('Effort', id: 208, overall_rank: 16, template_age: 40, gender: 'female') }
    let(:female_9) { instance_double('Effort', id: 209, overall_rank: 18, template_age: 20, gender: 'female') }
    let(:female_10) { instance_double('Effort', id: 210, overall_rank: 20, template_age: 30, gender: 'female') }

    let(:efforts) { [male_1, male_2, male_3, male_4, male_5, male_6, male_7, male_8, male_9, male_10,
                     female_1, female_2, female_3, female_4, female_5, female_6, female_7, female_8, female_9, female_10]
                        .sort_by(&:overall_rank) }

    let(:combined_overall) { results_categories(:overall) }
    let(:men_overall) { results_categories(:overall_men) }
    let(:women_overall) { results_categories(:overall_women) }
    let(:men_masters) { results_categories(:masters_men_40) }
    let(:women_masters) { results_categories(:masters_women_40) }
    let(:men_under_20) { results_categories(:under_20_men) }
    let(:women_under_20) { results_categories(:under_20_women) }
    let(:men_20s) { results_categories('20_to_29_men') }
    let(:women_20s) { results_categories('20_to_29_women') }
    let(:men_30s) { results_categories('30_to_39_men') }
    let(:women_30s) { results_categories('30_to_39_women') }
    let(:men_40s) { results_categories('40_to_49_men') }
    let(:women_40s) { results_categories('40_to_49_women') }

    before do
      efforts.each do |effort|
        allow(effort).to receive(:points=)
      end
    end

    context 'when aggregation_method is set to strict' do
      let(:aggregation_method) { :strict }

      context 'when categories is an empty array' do
        let(:categories) { [] }
        let(:podium_size) { 2 }

        it 'returns an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'when categories is a single overall rank category' do
        let(:categories) { [combined_overall] }
        let(:podium_size) { 2 }

        it 'returns efforts in a single array in the order given' do
          expect(subject).to eq([[101, 201]])
        end
      end

      context 'when categories consist of overall men and overall women' do
        let(:categories) { [men_overall, women_overall] }
        let(:podium_size) { 2 }

        it 'returns men and women in separate arrays in the order given' do
          expect(subject).to eq([[101, 102], [201, 202]])
        end
      end

      context 'when categories consist of overall men and women and masters men and women' do
        let(:categories) { [men_overall, women_overall, men_masters, women_masters] }
        let(:podium_size) { 2 }

        it 'returns men and women in the appropriate ranks' do
          expect(subject).to eq([[101, 102], [201, 202], [104, 107], [204, 207]])
        end
      end

      context 'when categories consist of several different categories' do
        let(:categories) { [men_overall, women_overall, men_masters, women_masters,
                            men_under_20, women_under_20, men_20s, women_20s,
                            men_30s, women_30s, men_40s, women_40s] }
        let(:podium_size) { 2 }

        it 'returns men and women in the appropriate ranks' do
          expect(subject).to eq([[101, 102], [201, 202], [104, 107], [204, 207],
                                 [105], [205], [101, 103], [201, 203],
                                 [102, 106], [202, 206], [104, 107], [204, 207]])
        end
      end
    end

    context 'when aggregation_method is set to inclusive' do
      let(:aggregation_method) { :inclusive }

      context 'when categories consist of overall men and women and masters men and women' do
        let(:categories) { [men_overall, women_overall, men_masters, women_masters] }
        let(:podium_size) { 2 }

        it 'returns men and women in the appropriate ranks' do
          expect(subject).to eq([[101, 102], [201, 202], [104, 107], [204, 207]])
        end
      end

      context 'when categories consist of several different categories' do
        let(:categories) { [men_overall, women_overall, men_masters, women_masters,
                            men_under_20, women_under_20, men_20s, women_20s,
                            men_30s, women_30s, men_40s, women_40s] }
        let(:podium_size) { 2 }

        it 'returns men and women in the appropriate ranks' do
          expect(subject).to eq([[101, 102], [201, 202], [104, 107], [204, 207],
                                 [105], [205], [103, 109], [203, 209],
                                 [106, 110], [206, 210], [108], [208]])
        end
      end
    end
  end
end
