module DataImport::Helpers
  class RaceResultUriBuilder

    def initialize(rr_event_id, rr_contest_id)
      @rr_event_id = rr_event_id
      @rr_contest_id = rr_contest_id
    end

    def full_uri
      "#{url}?#{params}"
    end

    private

    attr_reader :rr_event_id, :rr_contest_id

    def url
      "http://my.raceresult.com/#{rr_event_id}/RRPublish/json.php"
    end

    def params
      "name=#{rr_report_name}&contest=#{rr_contest_id}"
    end

    def rr_report_name
      'Result%20Lists%7CTracking'
    end
  end
end
