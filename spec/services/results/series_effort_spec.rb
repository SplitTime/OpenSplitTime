# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Results::SeriesEffort, type: :model do
  subject(:series_effort) { Results::SeriesEffort.new(person: person, efforts: efforts, event_series: event_series) }
  let(:person) { people(:series_finisher) }
  let(:efforts) { person.efforts }
  let(:event_series) { EventSeries.new }

  describe '#initialize' do
    context 'when provided with a person, efforts, and event_series that are consistent with each other' do
      it 'is valid' do
        expect(series_effort).to be_valid
      end
    end

    context 'when provided with a person and efforts that are not consistent with each other' do
      let(:person) { people(:series_finisher) }
      let(:other_person) { people(:finished_first_colorado_us) }
      let(:efforts) { other_person.efforts }
      let(:event_series) { EventSeries.new }

      it 'is not valid and includes a descriptive error' do
        expect(series_effort).not_to be_valid
        expect(series_effort.errors.full_messages).to include(/Efforts must match the provided person/)
      end
    end
  end
end
