FactoryBot.define do
  factory :import_job do
    user
    parent_type { "Lottery" }
    parent_id { 1 }
    format { :lottery_entrants }

    after(:build) do |import_job|
      import_job.file.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_lottery_entrants.csv")),
        filename: "test_lottery_entrants.csv",
        content_type: "text/csv"
      )
    end
  end
end
