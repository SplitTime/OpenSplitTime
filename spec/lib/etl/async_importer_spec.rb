# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::AsyncImporter do
  subject { ETL::AsyncImporter.new(import_job) }
  let(:import_job) { ::ImportJob.create!(user_id: 1, parent_type: "Lottery", parent_id: lottery.id, format: format) }
  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:format) { :lottery_entrants }
  let(:fast_division) { lottery.divisions.find_by(name: "Fast People") }
  let(:slow_division) { lottery.divisions.find_by(name: "Slow People") }
  let(:source_data) { file_fixture("test_lottery_entrants.csv") }

  before { import_job.file.attach(io: File.open(source_data), filename: "test_lottery_entrants.csv", content_type: "text/csv") }

  context "when importing lottery entrants" do
    it "creates new lottery entrants" do
      expect { subject.import! }.to change { ::LotteryEntrant.count }.by(3)
    end

    it "assigns expected attributes and divisions" do
      subject.import!
      entrant_1 = ::LotteryEntrant.find_by(first_name: "Bjorn", last_name: "Borg")
      entrant_2 = ::LotteryEntrant.find_by(first_name: "Charlie", last_name: "Brown")
      entrant_3 = ::LotteryEntrant.find_by(first_name: "Lucy", last_name: "Pendergrast")

      expect(entrant_1.division).to eq(fast_division)
      expect(entrant_2.division).to eq(slow_division)
      expect(entrant_3.division).to eq(slow_division)

      expect(entrant_1.number_of_tickets).to eq(4)
      expect(entrant_2.number_of_tickets).to eq(1)
      expect(entrant_3.number_of_tickets).to eq(3)
    end

    context "when the format is not recognized" do
      let(:format) { :non_existent }
      it "does not import any records" do
        expect { subject.import! }.not_to change { ::LotteryEntrant.count }
      end

      it "sets status and an error message on the import job" do
        subject.import!
        expect(import_job.status).to eq("failed")
        expect(import_job.error_message).to include("Format not recognized")
      end
    end
  end
end
