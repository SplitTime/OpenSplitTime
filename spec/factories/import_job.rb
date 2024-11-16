FactoryBot.define do
  factory :import_job do
    user
    association :parent, factory: :lottery
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
