FactoryGirl.define do
  factory :effort do
    sequence(:id, (100..109).cycle)
    sequence(:bib_number, (200..209).cycle)
    first_name 'Joe'
    sequence(:last_name) { |n| "LastName #{n}" }
    gender 'male'
    start_offset 0
    event
    person

    transient { without_slug false }

    after(:build, :stub) do |effort, evaluator|
      effort.slug = "#{effort.first_name&.parameterize}-#{effort.last_name&.parameterize}" unless evaluator.without_slug
    end

    factory :efforts_hardrock, class: Effort do
      sequence(:bib_number)
    end
  end
end
