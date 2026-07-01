# Fabricated, anonymized effort identity attributes for test data (random name + demographics).
# Shared by the create_records and simulate_records rake tasks.
class RandomEffortAttributes
  def self.generate
    new.to_h
  end

  def to_h
    gender = %w[male female].sample
    {
      first_name: FFaker::Name.send("first_name_#{gender}"),
      last_name: FFaker::Name.last_name,
      gender: gender,
      birthdate: FFaker::Time.between(16.years.ago, 75.years.ago).to_date,
      country_code: "US",
      state_code: Carmen::Country.coded("US").subregions.map(&:code).sample,
      city: FFaker::Address.city,
      emergency_contact: FFaker::Name.name,
      emergency_phone: FFaker::PhoneNumber.short_phone_number,
    }
  end
end
