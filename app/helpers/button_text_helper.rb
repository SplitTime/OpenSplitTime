# frozen_string_literal: true

module ButtonTextHelper
  BEACON_TEXT = {'findmespot.com' => 'SPOT Page',
                 'fastertracks.com' => 'FasterTracks',
                 'trackleaders.com' => 'SPOT via TrackLeaders',
                 'maprogress.com' => 'MAProgress Tracking'}

  REPORT_TEXT = {'strava.com' => 'Strava Page',
                 'fastertracks.com' => 'FasterTracks',
                 'fastestknowntime.proboards.com' => 'FKT Page'}

  def event_beacon_button_text(beacon_url)
    BEACON_TEXT
        .find { |known_url, _| beacon_url.to_s.include?(known_url) }
        .try(:last) || 'Event Locator Beacon'
  end

  def effort_beacon_button_text(beacon_url)
    BEACON_TEXT
        .find { |known_url, _| beacon_url.to_s.include?(known_url) }
        .try(:last) || 'Locator Beacon'
  end

  def effort_report_button_text(report_url)
    REPORT_TEXT
        .find { |known_url, _| report_url.to_s.include?(known_url) }
        .try(:last) || 'External Report'
  end
end
