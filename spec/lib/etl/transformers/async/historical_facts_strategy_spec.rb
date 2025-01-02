require "rails_helper"

RSpec.describe Etl::Transformers::Async::HistoricalFactsStrategy do
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
            first_name: "Bertha",
            last_name: "Klein",
            gender: "F",
            birthdate: "1966-04-20",
            address: "",
            city: "San Juan Capistrano",
            state: "CA",
            country: "USA",
            email: "bertha@example.com",
            phone: "94955512234",
            kind: "volunteer_year",
            comments: "Aid station work at Cunningham",
            year: 2024,
            ),
          OpenStruct.new(
            first_name: "Eloise",
            last_name: "Stokey",
            gender: "F",
            birthdate: "1955-04-10",
            address: "",
            city: "Dallas",
            state: "TX",
            country: "USA",
            email: "eloise@example.com",
            phone: "21455512234",
            kind: "volunteer_year_major",
            comments: "Aid Captain at Kroger",
            year: 2024,
          ),
        ]
      end

      it "does not report errors" do
        expect(subject.errors).to be_empty
      end

      it "returns proto_records and correct keys" do
        expect(proto_records).to be_present
        expect(proto_records).to all be_a(ProtoRecord)
        expect(proto_records.map { |pr| pr[:organization_id] }).to all eq(organization.id)

        %i[first_name last_name gender birthdate address state_code country_code email].each do |expected_key|
          expect(keys).to include(expected_key)
        end
      end

      it "correctly assigns values" do
        expect(proto_records.count).to eq(2)

        proto_record = proto_records.first
        expect(proto_record[:first_name]).to eq("Bertha")
        expect(proto_record[:last_name]).to eq("Klein")
        expect(proto_record[:gender]).to eq("female")
        expect(proto_record[:kind]).to eq("volunteer_year")

        proto_record = proto_records.second
        expect(proto_record[:first_name]).to eq("Eloise")
        expect(proto_record[:last_name]).to eq("Stokey")
        expect(proto_record[:gender]).to eq("female")
        expect(proto_record[:kind]).to eq("volunteer_year_major")
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
