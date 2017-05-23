class RaceResultFetcher

  def self.response_body(args)
    new(args).response_body
  end

  def initialize(args)
    @rr_event_id = args[:rr_event_id]
    @rr_contest_id = args[:rr_contest_id]
    @http_client = args[:http_client] || RestClient
  end

  def response
    @response ||= http_client.get("#{url}?#{params}")
  end

  def response_code
    response.code
  end

  def response_body
    JSON.parse(response.body)
  rescue JSON::ParserError
    {message: 'Unable to parse response'}
  end

  private

  attr_reader :rr_event_id, :rr_contest_id, :http_client

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
