# frozen_string_literal: true

RSpec.describe BibTimeRow do
  subject { BibTimeRow.new(query_result_row) }
  let(:query_result_row) do
    {"effort_id" => effort_id,
     "first_name" => first_name,
     "last_name" => last_name,
     "bib_number" => bib_number,
     "raw_times_attributes" => raw_times_attributes,
     "split_times_attributes" => split_times_attributes}
  end
  let(:effort_id) { 16_229 }
  let(:first_name) { "Tattie" }
  let(:last_name) { "Bailey" }
  let(:bib_number) { "101" }
  let(:raw_times_attributes) { "[{\"id\" : 84, \"entered_time\" : \"#{raw_military_time_1}\", \"source\" : \"ost-live-entry\", \"created_by\" : 1}, {\"id\" : 85, \"entered_time\" : \"#{raw_military_time_2}\", \"source\" : \"ost-remote abcd\", \"created_by\" : 1}]" }
  let(:split_times_attributes) { "[{\"id\" : 190522, \"lap\" : 1, \"military_time\" : \"#{split_military_time_1}\"}, {\"id\" : 190523, \"lap\" : 2, \"military_time\" : \"#{split_military_time_2}\"}]" }

  let(:raw_military_time_1) { "13:22:00" }
  let(:raw_military_time_2) { "14:22:00" }
  let(:split_military_time_1) { "13:39:00" }
  let(:split_military_time_2) { "13:49:00" }

  describe "#initialize" do
    context "when the query result row is valid" do
      it "initializes and assigns attributes" do
        expect { subject }.not_to raise_error
        expect(subject.effort_id).to eq(effort_id)
        expect(subject.first_name).to eq(first_name)
        expect(subject.last_name).to eq(last_name)
        expect(subject.bib_number).to eq(bib_number)
      end
    end
  end

  describe "#full_name" do
    context "when first_name and last_name are provided" do
      it "returns the full name" do
        expect(subject.full_name).to eq("Tattie Bailey")
      end
    end

    context "when the first_name and last_name are nil" do
      let(:first_name) { nil }
      let(:last_name) { nil }

      it "returns [Bib not found]" do
        expect(subject.full_name).to eq("[Bib not found]")
      end
    end
  end

  describe "#split_times" do
    let(:split_times) { subject.split_times }

    context "when split_times_attributes are valid" do
      it "creates an array of objects with lap and time data" do
        expect(split_times.map(&:lap)).to eq([1, 2])
        expect(split_times.map(&:military_time)).to eq([split_military_time_1, split_military_time_2])
      end
    end
  end

  describe "#raw_times" do
    let(:raw_times) { subject.raw_times }

    context "when raw_times_attributes are valid" do
      it "creates an array of objects with source and time data" do
        expect(raw_times.map(&:source_text)).to eq(["Live Entry (1)", "OSTR (abcd)"])
        expect(raw_times.map(&:military_time)).to eq([raw_military_time_1, raw_military_time_2])
      end
    end
  end

  describe "#largest_discrepancy" do
    it "returns the difference between the latest and earliest times" do
      expect(subject.largest_discrepancy).to eq(60.minutes)
    end

    context "when times are on either side of midnight" do
      let(:raw_military_time_1) { "23:45:00" }
      let(:raw_military_time_2) { "00:15:00" }
      let(:split_military_time_1) { "23:45:00" }
      let(:split_military_time_2) { "00:15:00" }

      it "accounts for the rollover in day" do
        expect(subject.largest_discrepancy).to eq(30.minutes)
      end
    end
  end
end
