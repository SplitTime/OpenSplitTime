require 'rails_helper'

RSpec.describe EffortRow, type: :model do
  let (:test_effort) { build_stubbed(:effort, state_code: 'CA', country_code: 'US', age: 30) }
  let (:test_person) { build_stubbed(:person) }

  describe '#initializate' do
    it 'instantiates an EffortRow if provided an effort' do
      expect { EffortRow.new(test_effort) }.not_to raise_error
    end
  end

  describe 'effort_attributes' do
    subject { EffortRow.new(test_effort) }

    it 'returns delegated effort attributes' do
      expect(subject.first_name).to eq(test_effort.first_name)
      expect(subject.last_name).to eq(test_effort.last_name)
      expect(subject.gender).to eq(test_effort.gender)
      expect(subject.state_code).to eq(test_effort.state_code)
    end

    it 'returns attributes from PersonalInfo module' do
      expect(subject.full_name).to eq(test_effort.full_name)
      expect(subject.bio_historic).to eq(test_effort.bio_historic)
      expect(subject.state_and_country).to eq(test_effort.state_and_country)
    end
  end

  describe '#run_status' do
    subject { EffortRow.new(test_effort) }
    it 'returns "Finished" when the run is finished' do
      allow(test_effort).to receive(:finished?).and_return(true)
      expect(subject.run_status).to eq('Finished')
    end

    it 'returns "Dropped" when the run is dropped' do
      allow(test_effort).to receive(:dropped?).and_return(true)
      expect(subject.run_status).to eq('Dropped')
    end

    it 'returns "In Progress" when the run is in progress' do
      allow(test_effort).to receive(:in_progress?).and_return(true)
      expect(subject.run_status).to eq('In Progress')
    end

    it 'returns "Not Started" when the run is neither finished nor dropped nor in progress' do
      allow(test_effort).to receive(:finished?).and_return(false)
      allow(test_effort).to receive(:dropped?).and_return(false)
      allow(test_effort).to receive(:in_progress?).and_return(false)
      expect(subject.run_status).to eq('Not Started')
    end
  end

  describe '#ultrasignup_finish_status' do
    subject { EffortRow.new(test_effort) }
    it 'returns 1 when the run is finished' do
      allow(test_effort).to receive(:finished?).and_return(true)
      expect(subject.ultrasignup_finish_status).to eq(1)
    end

    it 'returns 2 when the run is dropped' do
      allow(test_effort).to receive(:dropped?).and_return(true)
      expect(subject.ultrasignup_finish_status).to eq(2)
    end

    it 'returns a warning message when the run is in progress' do
      allow(test_effort).to receive(:in_progress?).and_return(true)
      expect(subject.ultrasignup_finish_status).to match(/is in progress/)
    end

    it 'returns 3 when the run is neither finished nor dropped nor in progress' do
      allow(test_effort).to receive(:finished?).and_return(false)
      allow(test_effort).to receive(:dropped?).and_return(false)
      allow(test_effort).to receive(:in_progress?).and_return(false)
      expect(subject.ultrasignup_finish_status).to eq(3)
    end
  end
end
