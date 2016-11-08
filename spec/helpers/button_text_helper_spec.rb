require 'rails_helper'

RSpec.describe ButtonTextHelper do
  describe 'event_beacon_button_text' do
    it 'returns "Event Locator Beacon" if no url is given' do
      expect(helper.event_beacon_button_text(nil)).to eq('Event Locator Beacon')
    end

    it 'returns "Event Locator Beacon" when url is not otherwise identified' do
      expect(helper.event_beacon_button_text('www.example.com/123')).to eq('Event Locator Beacon')
    end

    it 'returns "SPOT Page" if a SPOT url is given' do
      expect(helper.event_beacon_button_text('www.findmespot.com/123')).to eq('SPOT Page')
    end

    it 'returns "FasterTracks" if a fastertracks url is given' do
      expect(helper.event_beacon_button_text('www.fastertracks.com/456')).to eq('FasterTracks')
    end
  end

  describe 'effort_beacon_button_text' do
    it 'returns "Locator Beacon" if no url is given' do
      expect(helper.effort_beacon_button_text(nil)).to eq('Locator Beacon')
    end

    it 'returns "Locator Beacon" when url is not otherwise identified' do
      expect(helper.effort_beacon_button_text('www.example.com/123')).to eq('Locator Beacon')
    end

    it 'returns "SPOT Page" if a SPOT url is given' do
      expect(helper.effort_beacon_button_text('www.findmespot.com/123')).to eq('SPOT Page')
    end

    it 'returns "FasterTracks" if a fastertracks url is given' do
      expect(helper.effort_beacon_button_text('www.fastertracks.com/456')).to eq('FasterTracks')
    end
  end

  describe 'effort_report_button_text' do
    it 'returns "External Report" if no url is given' do
      expect(helper.effort_report_button_text(nil)).to eq('External Report')
    end

    it 'returns "External Report" when url is not otherwise identified' do
      expect(helper.effort_report_button_text('www.example.com/123')).to eq('External Report')
    end

    it 'returns "Strava Page" if a SPOT url is given' do
      expect(helper.effort_report_button_text('www.strava.com/123')).to eq('Strava Page')
    end

    it 'returns "FKT Page" if a fkt url is given' do
      expect(helper.effort_report_button_text('fastestknowntime.proboards.com/456')).to eq('FKT Page')
    end
  end
end