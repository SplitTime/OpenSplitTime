# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Transformers::Async::NullStrategy do
  subject { described_class.new(structs, options) }

  let(:options) do
    {
      import_job: import_job,
      parent: organization,
    }
  end
  let(:import_job) { create(:import_job, parent_type: "Organization", parent_id: organization&.id) }
  let(:organization) { organizations(:hardrock) }
  let(:proto_records) { subject.transform }
  let(:keys) { proto_records.first.to_h.keys }

  describe "#transform" do
    context "when given valid data" do
      let(:structs) do
        [
          OpenStruct.new(
            :Order_ID => 26861,
            :First_Name => "Emanuel",
            :Last_Name => "Nicolas",
            :gender => "M",
          ),
          OpenStruct.new(
            :Order_ID => 26864,
            :First_Name => "Dave",
            :Last_Name => "Conroy",
            :gender => "M",
          ),
        ]
      end

      it "does not report errors" do
        subject.transform
        expect(subject.errors).to be_empty
      end

      it "returns proto_records and correct keys" do
        expect(proto_records).to be_present
        expect(proto_records).to all be_a(ProtoRecord)

        %i[Order_ID First_Name Last_Name gender].each do |expected_key|
          expect(keys).to include(expected_key)
        end
      end

      it "returns one proto_record for each struct for lottery applications" do
        expect(proto_records.count).to eq(structs.count)
      end

      it "passes through all values without change" do
        proto_record = proto_records.first
        expect(proto_record[:Order_ID]).to eq(26861)
        expect(proto_record[:First_Name]).to eq("Emanuel")
        expect(proto_record[:Last_Name]).to eq("Nicolas")
        expect(proto_record[:gender]).to eq("M")
      end
    end

    context "when no structs are provided" do
      let(:structs) { [] }

      it "returns an empty array of proto_records without returning an error" do
        expect(proto_records).to eq([])
        expect(subject.errors).to eq([])
      end
    end
  end
end
