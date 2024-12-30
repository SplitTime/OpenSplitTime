FactoryBot.define do
  factory :lotteries_entrant_service_detail, class: Lotteries::EntrantServiceDetail do
    association :entrant, factory: :lottery_entrant

    trait :accepted do
      form_accepted_at { Time.zone.now }
      form_accepted_comments { "Thank you for your service" }
      completed_date { 30.days.ago }
    end

    trait :rejected do
      form_rejected_at { Time.zone.now }
      form_rejected_comments { "Form is not signed" }
    end

    trait :with_completed_form do
      transient do
        file_params do
          {
            file: Rails.root.join("spec", "fixtures", "files", "service_form.pdf"),
            filename: "service_form.pdf",
            content_type: "application/pdf",
          }
        end
      end

      after(:build) do |service_detail, evaluator|
        file_params = evaluator.file_params

        service_detail.completed_form.attach(
          io: File.open(file_params[:file]),
          filename: file_params[:filename],
          content_type: file_params[:content_type]
        )
      end
    end
  end
end
