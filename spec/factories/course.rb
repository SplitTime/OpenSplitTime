FactoryBot.define do
  factory :course do
    name { FFaker::Product.product }
    organization

    trait :with_description do
      description { FFaker::HipsterIpsum.phrase }
    end

    trait :with_splits do

      transient { splits_count { 4 } }
      transient { in_sub_splits_only { false } }
    end
  end
end
