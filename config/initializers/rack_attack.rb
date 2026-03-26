module Rack
  class Attack
    # Throttle all requests by IP (20 requests per minute)
    throttle("requests by IP", limit: 20, period: 60, &:ip)
  end
end
