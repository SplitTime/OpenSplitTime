require 'rails_helper'

RSpec.describe EffortShowView do
  subject { EffortShowView.new(effort) }
  let(:event) { build_stubbed(:event, efforts: efforts) }
  let(:efforts) { other_efforts + [effort] }

  before do
    allow(subject).to receive(:event).and_return(event)
    allow(subject).to receive(:effort).and_return(effort)
  end

  describe '#next_problem_effort' do
    context 'when the current effort is a problem effort' do
      let(:effort) { build_stubbed(:effort, data_status: :questionable) }

      context 'when other problem efforts exist' do
        let(:other_efforts) { build_stubbed_list(:effort, 2, data_status: :bad).sort_by(&:last_name) }

        context 'when the current effort is not last alphabetically' do
          before { effort.last_name = 'Aaron' }

          it 'returns the next problem effort alphabetically by last name' do
            expect(subject.next_problem_effort.last_name).to eq(other_efforts.first.last_name)
          end
        end

        context 'when the current effort is last alphabetically' do
          before { effort.last_name = 'Zyzyx' }

          it 'returns the first problem effort' do
            expect(subject.next_problem_effort).to eq(other_efforts.first)
          end
        end
      end

      context 'when no other problem efforts exist' do
        let(:other_efforts) { build_stubbed_list(:effort, 2, data_status: :good).sort_by(&:last_name) }

        it 'returns nil' do
          expect(subject.next_problem_effort).to be_nil
        end
      end
    end

    context 'when the current effort is not a problem effort' do
      let(:effort) { build_stubbed(:effort, data_status: :good) }

      context 'when other problem efforts exist' do
        let(:other_efforts) { build_stubbed_list(:effort, 2, data_status: :bad).sort_by(&:last_name) }

        it 'returns the first problem effort alphabetically by last name' do
          expect(subject.next_problem_effort).to eq(other_efforts.first)
        end
      end

      context 'when no other problem efforts exist' do
        let(:other_efforts) { build_stubbed_list(:effort, 2, data_status: :good).sort_by(&:last_name) }

        it 'returns nil' do
          expect(subject.next_problem_effort).to be_nil
        end
      end
    end
  end
end
