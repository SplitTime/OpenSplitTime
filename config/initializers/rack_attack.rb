module Rack
  class Attack
    THROTTLED_COUNTRIES = %w[CN SG].freeze

    # Throttle requests by IP for traffic from high-abuse countries (60 requests per minute).
    # Prefer CF-Connecting-IP so we throttle actual visitors rather than Cloudflare edge nodes,
    # which front thousands of unrelated clients and make per-IP limits meaningless.
    throttle("requests by IP", limit: 60, period: 60) do |req|
      next unless THROTTLED_COUNTRIES.include?(req.env["HTTP_CF_IPCOUNTRY"])

      req.env["HTTP_CF_CONNECTING_IP"].presence || req.ip
    end
  end
end
