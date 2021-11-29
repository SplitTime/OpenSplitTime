RSpec::Matchers.define :be_jsonapi_response_for do |model|
  match do |actual|
    parsed_actual = JSON.parse(actual)

    return false unless parsed_actual.dig('data', 'type') == model.camelcase(:lower)
    return false unless parsed_actual.dig('data', 'attributes').is_a?(Hash)

    true
  end
end
