FactoryBot.define do
  factory :import_job do
    user
    parent_type { "Lottery" }
    parent_id { 1 }
    format { :lottery_entrants }

    trait :with_file do
      transient do
        file { Rails.root.join("spec", "fixtures", "files", "test_lottery_entrants.csv") }
        filename { "test_lottery_entrants.csv" }
        content_type { "text/csv" }
      end

      after(:build) do |import_job, evaluator|
        import_job.files.attach(
          io: File.open(evaluator.file),
          filename: evaluator.filename,
          content_type: evaluator.content_type
        )
      end
    end
  end
end
