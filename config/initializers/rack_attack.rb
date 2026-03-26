module Rack
  class Attack
    THROTTLED_COUNTRIES = %w[CN SG].freeze

    # Throttle requests by IP for traffic from high-abuse countries (60 requests per minute)
    throttle("requests by IP", limit: 60, period: 60) do |req|
      req.ip if THROTTLED_COUNTRIES.include?(req.env["HTTP_CF_IPCOUNTRY"])
    end
  end
end
