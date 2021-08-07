RSpec::Matchers.define :trim_time_attribute do |attribute|
  match do |record|
    time_with_decimal = "2021-08-01 13:30:30.5"
    time_without_decimal = "2021-08-01 13:30:30"
    record.assign_attributes(attribute => time_with_decimal)
    record.validate

    record.send(attribute) == time_without_decimal
  end
end
