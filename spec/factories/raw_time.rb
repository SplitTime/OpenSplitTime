FactoryBot.define do
  factory :raw_time do
    event_group
    split_name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}".parameterize }
    bitkey { [SubSplit::IN_BITKEY, SubSplit::OUT_BITKEY].sample }
    bib_number { rand(1..999).to_s }
    entered_time { FFaker::Time.datetime }
    source { 'ost-test' }

    trait :with_absolute_time do
      entered_time { nil }
      absolute_time { FFaker::Time.datetime }
    end

    after(:build, :stub) do |raw_time|
      raw_time.run_callbacks(:validation)
    end
  end
end
