FactoryBot.define do
  factory :results_template do
    name { "#{FFaker::Name.first_name} #{FFaker::Name.first_name}" }
    aggregation_method { [:inclusive, :strict].sample }

    transient { without_slug { false } }

    after(:build, :stub) do |template, evaluator|
      template.slug = template.name&.parameterize unless evaluator.without_slug
    end
  end
end
