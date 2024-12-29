FactoryBot.define do
  factory :lotteries_entrant_service_detail, class: Lotteries::EntrantServiceDetail do
    trait :accepted do
      form_accepted_at { Time.zone.now }
      form_accepted_comments { "Thank you for your service" }
      completed_date { 30.days.ago }
    end

    trait :rejected do
      form_rejected_at { Time.zone.now }
      form_rejected_comments { "Form is not signed" }
    end
  end
end
