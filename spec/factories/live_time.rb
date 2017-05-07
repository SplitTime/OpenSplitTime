FactoryGirl.define do
  factory :live_time do
    event
    split
    sequence(:bib_number, 101)
    absolute_time '08:00:00'
    sequence(:batch)
    recorded_at Time.now
  end
end
