# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::AsyncImporter do
  subject { Etl::AsyncImporter.new(import_job) }
  let(:import_job) do
    create(
      :import_job,
      :with_files,
      file_params_array: file_params_array,
      parent: parent,
      format: format,
    )
  end

  let(:file_params_array) do
    [
      {
        file: source_data,
        filename: File.basename(source_data),
        content_type: "text/csv",
      }
    ]
  end
  let(:parent) { lottery }
  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:format) { :lottery_entrants }
  let(:fast_division) { lottery.divisions.find_by(name: "Fast People") }
  let(:slow_division) { lottery.divisions.find_by(name: "Slow People") }
  let(:source_data) { file_fixture("test_lottery_entrants.csv") }

  context "when a lottery entrant import file is valid and format is recognized" do
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
      expect(import_job.succeeded_count).to eq(3)
      expect(import_job.failed_count).to eq(0)
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
        expect(import_job.succeeded_count).to eq(0)
        expect(import_job.failed_count).to eq(1)
        expect(import_job.status).to eq("failed")
        expect(import_job.started_at).to be_present
        expect(import_job.elapsed_time).to be_present
        expect(import_job.parsed_errors.first.dig("detail", "messages")).to include(/Lottery division could not be found/)
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
        expect(import_job.succeeded_count).to eq(1)
        expect(import_job.failed_count).to eq(2)
        expect(import_job.status).to eq("failed")
        expect(import_job.started_at).to be_present
        expect(import_job.elapsed_time).to be_present
        expect(import_job.error_message).to include "Number of tickets can't be blank"
        expect(import_job.error_message).to include "Gender can't be blank"
      end
    end
  end

  context "when an event group entrant import file is valid and format is recognized" do
    let(:parent) { event_group }
    let(:event_group) { event_groups(:sum) }
    let(:format) { :event_group_entrants }
    let(:event_55k) { events(:sum_55k) }
    let(:event_100k) { events(:sum_100k) }
    let(:source_data) { file_fixture("test_efforts_nonbinary.csv") }

    it "creates new efforts" do
      expect { subject.import! }.to change { ::Effort.count }.by(3)
    end

    it "assigns expected attributes and events" do
      subject.import!
      entrant_1 = ::Effort.find_by(first_name: "Bjorn", last_name: "Borg")
      entrant_2 = ::Effort.find_by(first_name: "Pat", last_name: "Manticus")
      entrant_3 = ::Effort.find_by(first_name: "Lucy", last_name: "Pendergrast")

      expect(entrant_1.event).to eq(event_100k)
      expect(entrant_2.event).to eq(event_55k)
      expect(entrant_3.event).to eq(event_100k)

      expect(entrant_1.gender).to eq("male")
      expect(entrant_2.gender).to eq("nonbinary")
      expect(entrant_3.gender).to eq("female")
    end

    it "sets import job attributes properly" do
      subject.import!
      expect(import_job.row_count).to eq(3)
      expect(import_job.succeeded_count).to eq(3)
      expect(import_job.failed_count).to eq(0)
      expect(import_job.status).to eq("finished")
      expect(import_job.started_at).to be_present
      expect(import_job.elapsed_time).to be_present
      expect(import_job.error_message).to be_blank
    end
  end

  context "when a historical_facts import file is valid and format is recognized" do
    let(:parent) { organization }
    let(:organization) { organizations(:hardrock) }
    let(:format) { :hardrock_historical_facts }
    let(:event_2015) { events(:hardrock_2015) }
    let(:event_2016) { events(:hardrock_2016) }
    let(:source_data) { file_fixture("hardrock_historical_facts.csv") }

    it "does not result in errors" do
      subject.import!
      expect(subject.errors).to be_empty
    end

    it "creates new historical_facts" do
      expect { subject.import! }.to change { ::HistoricalFact.count }.by(83)
    end

    it "assigns expected attributes" do
      subject.import!
      expect(::HistoricalFact.pluck(:organization_id)).to all eq(organization.id)
      hf_1 = ::HistoricalFact.find_by(first_name: "Antony", last_name: "Grady", kind: :dns)

      expect(hf_1).to be_present
      expect(hf_1.gender).to eq("male")
      expect(hf_1.year).to eq(2019)
    end

    it "sets import job attributes properly" do
      subject.import!
      expect(import_job.row_count).to eq(11)
      expect(import_job.succeeded_count).to eq(83)
      expect(import_job.failed_count).to eq(0)
      expect(import_job.status).to eq("finished")
      expect(import_job.started_at).to be_present
      expect(import_job.elapsed_time).to be_present
      expect(import_job.error_message).to be_blank
    end
  end

  context "when the parent cannot be found" do
    let(:import_job) { build(:import_job, parent: nil) }

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
