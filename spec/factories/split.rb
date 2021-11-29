# frozen_string_literal: true

FactoryBot.define do
  sequence(:distance_from_start) do |d|
    d * 10000
  end

  sequence(:vert_gain_from_start) do |d|
    d * 100
  end

  sequence(:vert_loss_from_start) do |d|
    d * 100
  end

  factory :split do
    sequence(:base_name) { |n| "Split #{n}" }
    distance_from_start
    vert_gain_from_start
    vert_loss_from_start
    sub_split_bitmap { 65 }
    kind { :intermediate }
    course

    trait :with_lat_lon do
      latitude { rand(-70..70) }
      longitude { rand(-140..140) }
    end

    trait :start do
      base_name { 'Start Split' }
      distance_from_start { 0 }
      vert_gain_from_start { 0 }
      vert_loss_from_start { 0 }
      sub_split_bitmap { 1 }
      kind { :start }
    end

    trait :finish do
      base_name { 'Finish Split' }
      sub_split_bitmap { 1 }
      kind { :finish }
    end

    after(:build, :stub) { |split| split.send(:parameterize_base_name) }
  end
end
