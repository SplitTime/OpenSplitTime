require "rails_helper"

RSpec.describe Etl::Transformers::Async::BearHistoricalFactsStrategy do
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
            :Age => 20,
            :DOB => "2003-12-18",
            :Email => "shea_skiles@steubergreenfelder.name",
            :Address => "7463 Carmella Lakes",
            :City => "North Donna",
            :State => "CO",
            :Zip => 80202,
            :Country => "UZ",
            :Phone => "(796)778-1767 x7154",
            :Ever_finished => "Yes",
            :Reported_tickets => 2
          ),
          OpenStruct.new(
            :Order_ID => 26861,
            :First_Name => "Dave",
            :Last_Name => "Conroy",
            :gender => "M",
            :Age => 20,
            :DOB => "1973-07-11",
            :Email => "zulema@satterfield.name",
            :Address => "14181 Calvin Cove",
            :City => "Zacktown",
            :State => "MS",
            :Zip => 80202,
            :Country => "DE",
            :Phone => "453-682-9576",
            :Ever_finished => "No",
            :Reported_tickets => 1
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
        expect(proto_records.map { |pr| pr[:organization_id] }).to all eq(organization.id)

        %i[external_id first_name last_name gender birthdate address state_code country_code email].each do |expected_key|
          expect(keys).to include(expected_key)
        end
      end

      it "returns one proto_record for each struct for lottery applications" do
        lottery_application_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :lottery_application }
        expect(lottery_application_proto_records.size).to eq(structs.size)
        proto_record = lottery_application_proto_records.first
        expect(proto_record[:comments]).to eq("Ultrasignup")
        expect(proto_record[:external_id]).to eq(26861)
      end

      it "returns one proto_record per struct for ever finished" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :ever_finished }
        expect(previous_name_proto_records.count).to eq(2)
        expect(previous_name_proto_records.map { |pr| pr[:comments] }).to match_array(["yes", "no"])
      end

      it "returns one proto_record per struct for reported ticket counts" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :ticket_count_reported }
        expect(previous_name_proto_records.count).to eq(2)
        expect(previous_name_proto_records.map { |pr| pr[:quantity] }).to match_array([2,1])
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
