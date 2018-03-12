# frozen_string_literal: true

module ETL::Helpers
  class RaceResultUriBuilder

    def initialize(rr_event_id, rr_contest_id, rr_format)
      @rr_event_id = rr_event_id
      @rr_contest_id = rr_contest_id
      @rr_format = rr_format
    end

    def full_uri
      URI("#{url}?#{params}")
    end

    private

    attr_reader :rr_event_id, :rr_contest_id, :rr_format

    def url
      "http://my.raceresult.com/#{rr_event_id}/RRPublish/json.php"
    end

    def params
      "name=#{rr_report_name}&contest=#{rr_contest_id}"
    end

    def rr_report_name
      case rr_format.to_sym
      when :tracking
        'Result%20Lists%7CTracking'
      when :overall
        'Result%20Lists%7COverall%20Results%20-%20TO%20PRINT'
      else
        ''
      end
    end
  end
end
