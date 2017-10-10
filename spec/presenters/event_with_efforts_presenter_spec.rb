require 'rails_helper'

RSpec.describe EventWithEffortsPresenter do
  before do
    FactoryGirl.reload
  end
  subject { EventWithEffortsPresenter.new(event: event, params: prepared_params) }
  let(:event) { build_stubbed(:event_functional) }
  let(:prepared_params) { create(:prepared_params) }

  describe '#initialize' do
    it 'initializes given a PermittedParams object' do
      expect { subject }.not_to raise_error
    end

    it 'raises an error if event argument is not given' do
      expect { EventWithEffortsPresenter.new(params: prepared_params, random_param: 123) }
          .to raise_error(/must include event/)
    end

    it 'raises an error if any argument other than event and params is given' do
      expect { EventWithEffortsPresenter.new(event: event, params: prepared_params, random_param: 123) }
          .to raise_error(/may not include random_param/)
    end
  end

  describe '#sort_hash' do
    it 'returns a hash containing sort data' do
      expect(subject.sort_hash).to eq({'name' => :asc, 'age' => :desc})
    end
  end

  describe '#sort_string' do
    it 'returns a sort string in jsonapi format based on the sort_hash' do
      expect(subject.sort_string).to eq('name,-age')
    end
  end

  describe '#search_text' do
    it 'returns a string containing search text' do
      expect(subject.search_text).to eq('jane')
    end
  end

  describe '#filter_hash' do
    it 'returns a hash containing filter requirements' do
      expect(subject.filter_hash).to eq({'state_code' => %w(NM NY BC), 'gender' => [1]})
    end
  end
end
