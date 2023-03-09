# frozen_string_literal: true

$redis = Redis.new(url: OstConfig.redis_url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
