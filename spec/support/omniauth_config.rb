OmniAuth.configure do |config|
  config.test_mode = true

  config.on_failure = proc do |env|
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  end
end
