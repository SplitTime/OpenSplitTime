RSpec::Matchers.define :localize_time_attribute do |attribute|
  match do |record|
    time_zone_string = 'Mountain Time (US & Canada)'
    allow(record).to receive(:home_time_zone).and_return(time_zone_string)
    record.assign_attributes(attribute => Time.current)

    utc_time = record.send(attribute)
    localized_time = record.send("#{attribute}_local")

    utc_time == localized_time &&
        localized_time.time_zone.name == time_zone_string
  end
end
