# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::AsyncImporter do
  subject { ETL::AsyncImporter.new(import_job) }
  let(:import_job) { create(:import_job, parent_type: "Lottery", parent_id: lottery_id, format: format) }
  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:lottery_id) { lottery.id }
  let(:format) { :lottery_entrants }
  let(:fast_division) { lottery.divisions.find_by(name: "Fast People") }
  let(:slow_division) { lottery.divisions.find_by(name: "Slow People") }
  let(:source_data) { file_fixture("test_lottery_entrants.csv") }

  before { import_job.file.attach(io: File.open(source_data), filename: "test_lottery_entrants.csv", content_type: "text/csv") }

  context "when the import file is valid and format is recognized" do
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

    it "sets import job attributes properly" do
      subject.import!
      expect(import_job.row_count).to eq(3)
      expect(import_job.success_count).to eq(3)
      expect(import_job.failure_count).to eq(0)
      expect(import_job.status).to eq("finished")
      expect(import_job.started_at).to be_present
      expect(import_job.elapsed_time).to be_present
      expect(import_job.error_message).to be_blank
    end

    context "when the import file has rows that will not transform" do
      let(:source_data) { file_fixture("test_lottery_entrants_transform_problems.csv") }
      it "does not create new lottery entrants for those rows" do
        expect { subject.import! }.not_to change { ::LotteryEntrant.count }
      end

      it "sets import job attributes properly" do
        subject.import!
        expect(import_job.row_count).to eq(3)
        expect(import_job.success_count).to eq(0)
        expect(import_job.failure_count).to eq(1)
        expect(import_job.status).to eq("failed")
        expect(import_job.started_at).to be_present
        expect(import_job.elapsed_time).to be_present
        expect(import_job.parsed_errors.first.dig("detail", "messages")).to include /Division could not be found/
        expect(import_job.parsed_errors.first.dig("detail", "row_index")).to eq(1)
      end
    end

    context "when all rows transform but some will not load" do
      let(:source_data) { file_fixture("test_lottery_entrants_load_problems.csv") }
      it "does not create new lottery entrants" do
        expect { subject.import! }.to change { ::LotteryEntrant.count }.by(1)
      end

      it "sets import job attributes properly" do
        subject.import!
        expect(import_job.row_count).to eq(3)
        expect(import_job.success_count).to eq(1)
        expect(import_job.failure_count).to eq(2)
        expect(import_job.status).to eq("failed")
        expect(import_job.started_at).to be_present
        expect(import_job.elapsed_time).to be_present
        expect(import_job.error_message).to include "Number of tickets can't be blank"
        expect(import_job.error_message).to include "Gender can't be blank"
      end
    end
  end

  context "when the parent cannot be found" do
    let(:lottery_id) { 0 }
    it "does not import any records" do
      expect { subject.import! }.not_to change { ::LotteryEntrant.count }
    end

    it "sets status and an error message on the import job" do
      subject.import!
      expect(import_job.status).to eq("failed")
      expect(import_job.error_message).to include("Parent is missing")
    end
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
