FactoryBot.define do
  factory :results_category do
    name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}" }
    male { true }
    female { true }
    low_age { rand(12..60) }
    high_age { low_age + rand(9..20) }

    trait :male do
      male { true }
      female { false }
    end

    trait :female do
      male { false }
      female { true }
    end
  end
end
