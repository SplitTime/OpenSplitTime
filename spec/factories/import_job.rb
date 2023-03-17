FactoryBot.define do
  factory :import_job do
    user
    parent_type { "Lottery" }
    parent_id { 1 }
    format { :lottery_entrants }

    trait :with_files do
      transient do
        file_params_array do
          [
            {
              file: Rails.root.join("spec", "fixtures", "files", "test_lottery_entrants.csv"),
              filename: "test_lottery_entrants.csv",
              content_type: "text/csv",
            },
          ]
        end
      end

      after(:build) do |import_job, evaluator|
        evaluator.file_params_array.each do |file_params|
          import_job.files.attach(
            io: File.open(file_params[:file]),
            filename: file_params[:filename],
            content_type: file_params[:content_type]
          )
        end
      end
    end
  end
end
