# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Results::SeriesEffort, type: :model do
  subject(:series_effort) { Results::SeriesEffort.new(person: person, efforts: efforts, event_series: event_series) }

  describe '#initialize' do
    context 'when provided with a person, efforts, and event_series that are consistent with each other' do
      let(:person) { people.select { |person| person.efforts.size > 1} }
      let(:efforts) { person.efforts }
      let(:event_series) { EventSeries.new }

      it 'is valid' do
        pp person.map(&:slug)
      end
    end
  end
end
