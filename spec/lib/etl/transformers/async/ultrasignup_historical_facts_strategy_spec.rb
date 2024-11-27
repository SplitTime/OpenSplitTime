# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::Transformers::Async::UltrasignupHistoricalFactsStrategy do
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
            :DOB => "2003-12-18",
            :Email => "shea_skiles@steubergreenfelder.name",
            :Address => "7463 Carmella Lakes",
            :City => "North Donna",
            :State => "CO",
            :Country => "UZ",
            :Phone => "(796)778-1767 x7154",
            :emergency_name => "No",
            :emergency_phone => "NA",
            :Volunteer_description => "Cunningham 2021, 2022, 2023",
            :Ever_finished => "No",
            :Previous_names_1 => "NONE",
            :Previous_names_2 => "",
            :DNS_since_finish => 3,
            :Qualifier => "2023 OCT: Diagonale des Fous (Reunion Is)",
            :Years_volunteered => 3
          ),
          OpenStruct.new(
            :Order_ID => 26864,
            :First_Name => "Dave",
            :Last_Name => "Conroy",
            :gender => "M",
            :DOB => "1973-07-11",
            :Email => "zulema@satterfield.name",
            :Address => "14181 Calvin Cove",
            :City => "Zacktown",
            :State => "MS",
            :Country => "DE",
            :Phone => "453-682-9576",
            :emergency_name => "Carleen Paucek",
            :emergency_phone => "None",
            :Volunteer_description => "",
            :Ever_finished => "No",
            :Previous_names_1 => "David Conroy",
            :Previous_names_2 => "david conroy",
            :DNS_since_finish => 1,
            :Qualifier => "2023 AUG: Bigfoot 200",
            :Years_volunteered => 0
          ),
          OpenStruct.new(
            :Order_ID => 26868,
            :First_Name => "Louis",
            :Last_Name => "Benoit",
            :gender => "M",
            :DOB => "04/22/1993",
            :Email => "louis@gmail.com",
            :Address => "678 Allée du bois",
            :City => "ARNAS",
            :State => "",
            :Country => "FRA",
            :Phone => 33688547410,
            :emergency_name => "Françoise Benoit",
            :emergency_phone => 33682847631,
            :Volunteer_description => "",
            :Ever_finished => "No",
            :Previous_names_1 => "louis benoit",
            :Previous_names_2 => "",
            :DNS_since_finish => 0,
            :Qualifier => "2023 SEPT: Tor de Geants (Italy)",
            :Years_volunteered => 0
          ),
          OpenStruct.new(
            :Order_ID => 26891,
            :First_Name => "Marie",
            :Last_Name => "Sanjust",
            :gender => "F",
            :DOB => "07/07/1999",
            :Email => "marie@gmail.com",
            :Address => "54 Majestic Valley Road, Aneia",
            :City => "Johannesburg",
            :State => "Gauteng",
            :Country => "ZAF",
            :Phone => 27833123123,
            :emergency_name => "Promo",
            :emergency_phone => 27724373177,
            :Volunteer_description => "",
            :Ever_finished => "Yes",
            :Previous_names_1 => "Marie Antoinette",
            :Previous_names_2 => "Maria Sanjust",
            :DNS_since_finish => 0,
            :Qualifier => "2023 Nov: Ultra-Trail Cape Town",
            :Years_volunteered => 0
          )
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

        %i[first_name last_name gender birthdate address state_code country_code email].each do |expected_key|
          expect(keys).to include(expected_key)
        end
      end

      it "returns one proto_record for each struct for lottery applications" do
        lottery_application_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :lottery_application }
        expect(lottery_application_proto_records.size).to eq(structs.size)
        proto_record = lottery_application_proto_records.first
        expect(proto_record[:comments]).to eq("Ultrasignup order id: 26861")
      end

      it "returns one proto_record for each multi-year volunteer fact" do
        volunteer_multi_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :volunteer_multi }
        expect(volunteer_multi_proto_records.count).to eq(1)
        proto_record = volunteer_multi_proto_records.first
        expect(proto_record[:quantity]).to eq(3)
        expect(proto_record[:year]).to eq(2024)
        expect(proto_record[:comments]).to eq("Cunningham 2021, 2022, 2023")
      end

      it "returns one proto_record for each reported qualifier" do
        qualifier_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :qualifier_finish }
        expect(qualifier_proto_records.count).to eq(4)
        expect(qualifier_proto_records.map { |pr| pr[:comments] })
          .to match_array(["2023 AUG: Bigfoot 200", "2023 Nov: Ultra-Trail Cape Town", "2023 OCT: Diagonale des Fous (Reunion Is)", "2023 SEPT: Tor de Geants (Italy)"])
      end

      it "returns one proto_record for each provided emergency contact" do
        emergency_contact_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :emergency_contact }
        expect(emergency_contact_proto_records.count).to eq(3)
        expect(emergency_contact_proto_records.map { |pr| pr[:comments] }).to match_array(["Carleen Paucek", "Françoise Benoit, 33682847631", "Promo, 27724373177"])
      end

      it "returns one proto_record for each provided previous name, ignoring junk and identical names" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :previous_name }
        expect(previous_name_proto_records.count).to eq(3)
        expect(previous_name_proto_records.map { |pr| pr[:comments] }).to match_array(["David Conroy", "Marie Antoinette", "Maria Sanjust"])
      end

      it "returns one proto_record per struct for ever finished" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :ever_finished }
        expect(previous_name_proto_records.count).to eq(4)
        expect(previous_name_proto_records.map { |pr| pr[:comments] }).to match_array(["no", "no", "no", "yes"])
      end

      it "returns one proto_record per struct for DNS since finish" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :dns_since_finish }
        expect(previous_name_proto_records.count).to eq(4)
        expect(previous_name_proto_records.map { |pr| pr[:quantity] }).to match_array([0,0,1,3])
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
