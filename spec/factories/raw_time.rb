FactoryBot.define do
  factory :raw_time do
    event_group
    split_name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}".parameterize }
    bitkey { [SubSplit::IN_BITKEY, SubSplit::OUT_BITKEY].sample }
    bib_number { rand(1..999).to_s }
    absolute_time { FFaker::Time.datetime }
    source { 'ost-test' }

    after(:build, :stub) do |raw_time|
      raw_time.run_callbacks(:validation)
    end
  end
end
