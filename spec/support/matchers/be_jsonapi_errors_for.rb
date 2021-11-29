RSpec::Matchers.define :be_jsonapi_errors do
  match do |actual|
    parsed_actual = JSON.parse(actual)
    parsed_actual.has_key?('errors') &&
        parsed_actual['errors'].is_a?(Array) &&
        parsed_actual['errors'].all? { |error_object| error_object.has_key?('title') }
  end
end
