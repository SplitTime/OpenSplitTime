OmniAuth.configure do |config|
  config.test_mode = true

  config.on_failure = Proc.new { |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  }
end
