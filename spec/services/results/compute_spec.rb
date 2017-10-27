RSpec.describe Results::Compute do
  describe '.perform' do
    subject do
      Results::Compute.perform(efforts: efforts, categories: categories, podium_size: podium_size, method: method)
          .map { |category| category.efforts.map(&:id) }
    end

    let(:male_1) { instance_double('Effort', id: 101, overall_rank: 1, age: 20, gender: 'male') }
    let(:male_2) { instance_double('Effort', id: 102, overall_rank: 3, age: 30, gender: 'male') }
    let(:male_3) { instance_double('Effort', id: 103, overall_rank: 5, age: 20, gender: 'male') }
    let(:male_4) { instance_double('Effort', id: 104, overall_rank: 7, age: 40, gender: 'male') }
    let(:male_5) { instance_double('Effort', id: 105, overall_rank: 9, age: 10, gender: 'male') }
    let(:male_6) { instance_double('Effort', id: 106, overall_rank: 11, age: 30, gender: 'male') }
    let(:male_7) { instance_double('Effort', id: 107, overall_rank: 13, age: 40, gender: 'male') }
    let(:male_8) { instance_double('Effort', id: 108, overall_rank: 15, age: 40, gender: 'male') }
    let(:male_9) { instance_double('Effort', id: 109, overall_rank: 17, age: 20, gender: 'male') }
    let(:male_10) { instance_double('Effort', id: 110, overall_rank: 19, age: 30, gender: 'male') }
    let(:female_1) { instance_double('Effort', id: 201, overall_rank: 2, age: 20, gender: 'female') }
    let(:female_2) { instance_double('Effort', id: 202, overall_rank: 4, age: 30, gender: 'female') }
    let(:female_3) { instance_double('Effort', id: 203, overall_rank: 6, age: 20, gender: 'female') }
    let(:female_4) { instance_double('Effort', id: 204, overall_rank: 8, age: 40, gender: 'female') }
    let(:female_5) { instance_double('Effort', id: 205, overall_rank: 10, age: 10, gender: 'female') }
    let(:female_6) { instance_double('Effort', id: 206, overall_rank: 12, age: 30, gender: 'female') }
    let(:female_7) { instance_double('Effort', id: 207, overall_rank: 14, age: 40, gender: 'female') }
    let(:female_8) { instance_double('Effort', id: 208, overall_rank: 16, age: 40, gender: 'female') }
    let(:female_9) { instance_double('Effort', id: 209, overall_rank: 18, age: 20, gender: 'female') }
    let(:female_10) { instance_double('Effort', id: 210, overall_rank: 20, age: 30, gender: 'female') }

    let(:efforts) { [male_1, male_2, male_3, male_4, male_5, male_6, male_7, male_8, male_9, male_10,
                     female_1, female_2, female_3, female_4, female_5, female_6, female_7, female_8, female_9, female_10].shuffle }

    let(:combined_overall) { Results::Categories.find(:combined_overall) }
    let(:men_overall) { Results::Categories.find(:men_overall) }
    let(:women_overall) { Results::Categories.find(:women_overall) }
    let(:men_masters) { Results::Categories.find(:men_masters) }
    let(:women_masters) { Results::Categories.find(:women_masters) }
    let(:men_under_20) { Results::Categories.find(:men_under_20) }
    let(:women_under_20) { Results::Categories.find(:women_under_20) }
    let(:men_20s) { Results::Categories.find(:men_20s) }
    let(:women_20s) { Results::Categories.find(:women_20s) }
    let(:men_30s) { Results::Categories.find(:men_30s) }
    let(:women_30s) { Results::Categories.find(:women_30s) }
    let(:men_40s) { Results::Categories.find(:men_40s) }
    let(:women_40s) { Results::Categories.find(:women_40s) }

    context 'when mode is set to strict' do
      let(:method) { :strict }

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

        it 'returns efforts in a single array sorted by overall rank' do
          expect(subject).to eq([[101, 201]])
        end
      end

      context 'when categories consist of overall men and overall women' do
        let(:categories) { [men_overall, women_overall] }
        let(:podium_size) { 2 }

        it 'returns men and women in separate arrays ordered by overall rank' do
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

    context 'when mode is set to inclusive' do
      let(:method) { :inclusive }

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
