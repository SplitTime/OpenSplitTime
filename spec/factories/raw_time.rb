FactoryBot.define do
  factory :raw_time do
    event_group
    entered_time { "12:34:56" }
    split_name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}".parameterize }
    bitkey { [SubSplit::IN_BITKEY, SubSplit::OUT_BITKEY].sample }
    bib_number { rand(1..999).to_s }
    absolute_time { FFaker::Time.datetime }
    source { "ost-test" }
    creator { nil }
    reviewer { nil }

    after(:build, :stub) do |raw_time|
      # Temporarily clear User.current to prevent Auditable from setting created_by
      original_user = User.current
      User.current = nil
      
      raw_time.run_callbacks(:validation)
      
      # Restore User.current
      User.current = original_user
    end
  end
end
