VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end
