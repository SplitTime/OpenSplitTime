# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::ImportJobs::BuildFromLottery do
  subject { described_class.new(event: event, lottery: lottery) }
  let(:event) { events(:hardrock_2016) }
  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

  describe "#perform" do
    let(:import_job) { subject.perform }
    context "when all requirements are met" do
      let(:expected_first_row) do
        {
          "birthdate"=>"1993-06-06",
          "city"=>"West Vicentafurt",
          "country_code"=>"US",
          "first_name"=>"Jospeh",
          "gender"=>"female",
          "last_name"=>"Barrows",
          "state_code"=>"MS",
        }
      end

      let(:expected_last_row) do
        {
          "birthdate"=>"1986-10-23",
          "city"=>"Beerbury",
          "country_code"=>"US",
          "first_name"=>"Mitsuko",
          "gender"=>"female",
          "last_name"=>"Wilkinson",
          "state_code"=>"PA",
        }
      end

      it "builds an import job with expected attributes" do
        expect(import_job).to be_a(::ImportJob)
        expect(import_job.parent_type).to eq("Event")
        expect(import_job.parent_id).to eq(event.id)
        expect(import_job.format).to eq("event_efforts_from_lottery")
      end

      it "attaches a file" do
        expect(import_job.file).to be_attached
      end

      it "writes expected data to the file" do
        import_job.user = users(:admin_user)
        import_job.save!

        file_contents = import_job.file.download
        result = CSV.parse(file_contents, headers: true)
        expect(result.size).to eq(5)
        expect(result[0].to_h).to eq(expected_first_row)
        expect(result[-1].to_h).to eq(expected_last_row)
      end
    end

    context "when the event is from a different organization than the lottery" do
      let(:event) { events(:ramble) }
      it "raises an error" do
        expect { import_job }.to raise_error ArgumentError
      end
    end
  end
end
