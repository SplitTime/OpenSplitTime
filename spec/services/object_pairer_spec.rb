require 'rails_helper'

RSpec.describe ObjectPairer do
  subject { ObjectPairer.new(objects: objects, identical_attributes: identical_attributes, pairing_criteria: pairing_criteria) }
  let(:raw_time_1) { build_stubbed(:raw_time, bib_number: 10, split_name: 'Aid 1', bitkey: 1) }
  let(:raw_time_2) { build_stubbed(:raw_time, bib_number: 10, split_name: 'Aid 1', bitkey: 64) }
  let(:raw_time_3) { build_stubbed(:raw_time, bib_number: 11, split_name: 'Aid 1', bitkey: 1) }
  let(:raw_time_4) { build_stubbed(:raw_time, bib_number: 11, split_name: 'Aid 1', bitkey: 64) }
  let(:raw_time_5) { build_stubbed(:raw_time, bib_number: 10, split_name: 'Aid 2', bitkey: 1) }
  let(:raw_time_6) { build_stubbed(:raw_time, bib_number: 10, split_name: 'Aid 2', bitkey: 64) }
  let(:raw_time_7) { build_stubbed(:raw_time, bib_number: 10, split_name: 'Aid 1', bitkey: 64) }

  describe '#pair' do
    context 'using bib_number as the only identical attribute' do
      let(:identical_attributes) { :bib_number }

      context 'when all objects can be paired' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{split_name: 'Aid 1', bitkey: 1}, {split_name: 'Aid 1', bitkey: 64}] }

        it 'returns an array of paired object arrays' do
          expected = [[raw_time_1, raw_time_2], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when objects have more than one pairing possibility' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_7] }
        let(:pairing_criteria) { [{split_name: 'Aid 1', bitkey: 1}, {split_name: 'Aid 1', bitkey: 64}] }

        it 'returns an array of paired object arrays and pairs the additional object with nil' do
          expected = [[raw_time_1, raw_time_2], [nil, raw_time_7], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because they do not match pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_4, raw_time_5, raw_time_6] }
        let(:pairing_criteria) { [{split_name: 'Aid 1', bitkey: 1}, {split_name: 'Aid 1', bitkey: 64}] }

        it 'returns an array of objects paired with nils' do
          expected = [[raw_time_1, nil], [nil, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because right pairing criteria are nil' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{split_name: 'Aid 1', bitkey: 1}, {split_id: nil, bitkey: nil}] }

        it 'returns an array of objects paired with nils' do
          expected = [[raw_time_1, nil], [raw_time_3, nil]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because left pairing criteria are nil' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{split_id: nil, bitkey: nil}, {split_name: 'Aid 1', bitkey: 64}] }

        it 'returns an array of objects paired with nils' do
          expected = [[nil, raw_time_2], [nil, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects match the pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{split_name: 'Aid 2', bitkey: 1}, {split_name: 'Aid 2', bitkey: 64}] }

        it 'returns an empty array' do
          expected = []
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when all objects match both left and right pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{class: RawTime}, {class: RawTime}] }

        it 'alternates objects to left and right' do
          expected = [[raw_time_1, raw_time_2], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end
    end

    context 'using bib_number and split_id as identical attributes' do
      let(:identical_attributes) { [:bib_number, :split_id] }

      context 'when all objects can be paired using split_id as an identical attribute' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{bitkey: 1}, {bitkey: 64}] }

        it 'returns an array of paired object arrays' do
          expected = [[raw_time_1, raw_time_2], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when objects have more than one pairing possibility' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4, raw_time_7] }
        let(:pairing_criteria) { [{bitkey: 1}, {bitkey: 64}] }

        it 'returns an array of paired object arrays and pairs the additional object with nil' do
          expected = [[raw_time_1, raw_time_2], [nil, raw_time_7], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because they do not match pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_4, raw_time_5] }
        let(:pairing_criteria) { [{bitkey: 1}, {bitkey: 64}] }

        it 'returns an array of objects paired with nils' do
          expected = [[raw_time_1, nil], [nil, raw_time_4], [raw_time_5, nil]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because right pairing criteria are nil' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{bitkey: 1}, {bitkey: nil}] }

        it 'returns an array of objects paired with nils' do
          expected = [[raw_time_1, nil], [raw_time_3, nil]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects can be paired because left pairing criteria are nil' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{bitkey: nil}, {bitkey: 64}] }

        it 'returns an array of objects paired with nils' do
          expected = [[nil, raw_time_2], [nil, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when no objects match the pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{bitkey: 99}, {bitkey: 100}] }

        it 'returns an empty array' do
          expected = []
          expect(subject.pair).to match_array(expected)
        end
      end

      context 'when all objects match both left and right pairing criteria' do
        let(:objects) { [raw_time_1, raw_time_2, raw_time_3, raw_time_4] }
        let(:pairing_criteria) { [{class: RawTime}, {class: RawTime}] }

        it 'alternates objects to left and right' do
          expected = [[raw_time_1, raw_time_2], [raw_time_3, raw_time_4]]
          expect(subject.pair).to match_array(expected)
        end
      end
    end
  end
end
