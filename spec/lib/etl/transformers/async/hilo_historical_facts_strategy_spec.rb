require "rails_helper"

RSpec.describe Etl::Transformers::Async::HiloHistoricalFactsStrategy do
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
            Master_ID: 1,
            First_Name: "Robena",
            Last_Name: "Stark",
            Full_name: "Robena Stark",
            Email: "robena@gmail.com",
            Gender: "F",
            Birthdate: "2/2/1999",
            Address: "Bernhard Point",
            City: "Hesselchester",
            State: "CT",
            Country: "US",
            Result_2017: "",
            Result_2018: "",
            Result_2019: "",
            Result_2021: "",
            Result_2022: "",
            Result_2023: "",
            Result_2024: "",
            Total_DNF: 0,
            Total_Finishes: 0,
            App_2020: "",
            App_2021: "",
            App_2022: "",
            App_2023: "",
            App_2024: "A",
            Reset_2020: "",
            Reset_2021: "",
            Reset_2022: "",
            Reset_2023: "",
            Reset_2024: "",
            Count_2020: "",
            Count_2021: "",
            Count_2022: "",
            Count_2023: "",
            Count_2024: 1,
            Total_Count: 1,
            "2025_App?": "Yes",
            Reg_Number: 1234,
            TW_Boost: "",
            Vol_Points: ""
          ),
          OpenStruct.new(
            Master_ID: 2,
            First_Name: "Providencia",
            Last_Name: "Ward",
            Full_name: "Providencia Ward",
            Email: "providencia@yahoo.com",
            Gender: "F",
            Birthdate: "3/3/1982",
            Address: "Joye Camp",
            City: "West Michiko",
            State: "MT",
            Country: "US",
            Result_2017: "",
            Result_2018: "",
            Result_2019: "",
            Result_2021: "",
            Result_2022: "",
            Result_2023: "",
            Result_2024: "",
            Total_DNF: 0,
            Total_Finishes: 0,
            App_2020: "",
            App_2021: "",
            App_2022: "",
            App_2023: "A",
            App_2024: "A",
            Reset_2020: "",
            Reset_2021: "",
            Reset_2022: "",
            Reset_2023: "",
            Reset_2024: "",
            Count_2020: "",
            Count_2021: "",
            Count_2022: "",
            Count_2023: 1,
            Count_2024: 1,
            Total_Count: 2,
            "2025_App?": "",
            Reg_Number: "",
            TW_Boost: "",
            Vol_Points: ""
          ),
          OpenStruct.new(
            Master_ID: 3,
            First_Name: "Ricky",
            Last_Name: "Russel",
            Full_name: "Ricky Russel",
            Email: "rickruss@gmail.com",
            Gender: "M",
            Birthdate: "4/4/1966",
            Address: "Glover Pines",
            City: "South Ildaton",
            State: "NH",
            Country: "US",
            Result_2017: "",
            Result_2018: "",
            Result_2019: "DNF",
            Result_2021: "",
            Result_2022: "",
            Result_2023: "",
            Result_2024: "",
            Total_DNF: 1,
            Total_Finishes: 0,
            App_2020: "",
            App_2021: "",
            App_2022: "A",
            App_2023: "",
            App_2024: "A",
            Reset_2020: "",
            Reset_2021: "",
            Reset_2022: "",
            Reset_2023: "",
            Reset_2024: "",
            Count_2020: "",
            Count_2021: "",
            Count_2022: 1,
            Count_2023: "",
            Count_2024: 1,
            Total_Count: 2,
            "2025_App?": "Yes",
            Reg_Number: 2345,
            TW_Boost: 8,
            Vol_Points: ""
          ),
          OpenStruct.new(
            Master_ID: 4,
            First_Name: "Cary",
            Last_Name: "Ebert",
            Full_name: "Cary Ebert",
            Email: "thumbsup@gmail.com",
            Gender: "M",
            Birthdate: "",
            Address: "Lily Forge",
            City: "Schadentown",
            State: "NH",
            Country: "US",
            Result_2017: "",
            Result_2018: "",
            Result_2019: "",
            Result_2021: "",
            Result_2022: "",
            Result_2023: "",
            Result_2024: "Finish",
            Total_DNF: 0,
            Total_Finishes: 1,
            App_2020: "",
            App_2021: "",
            App_2022: "",
            App_2023: "",
            App_2024: "A",
            Reset_2020: "",
            Reset_2021: "",
            Reset_2022: "",
            Reset_2023: "",
            Reset_2024: "R",
            Count_2020: 0,
            Count_2021: 0,
            Count_2022: 0,
            Count_2023: 0,
            Count_2024: 0,
            Total_Count: 0,
            "2025_App?": "",
            Reg_Number: "",
            TW_Boost: "",
            Vol_Points: ""
          ),
          OpenStruct.new(
            Master_ID: 5,
            First_Name: "Dionna",
            Last_Name: "Kreiger",
            Full_name: "Dionna Kreiger",
            Email: "dionnak@hotmail.com",
            Gender: "F",
            Birthdate: "5/5/1977",
            Address: "Dach Mill",
            City: "Micahburgh",
            State: "TN",
            Country: "US",
            Result_2017: "",
            Result_2018: "",
            Result_2019: "",
            Result_2021: "",
            Result_2022: "",
            Result_2023: "",
            Result_2024: "",
            Total_DNF: 0,
            Total_Finishes: 0,
            App_2020: "A",
            App_2021: "A",
            App_2022: "",
            App_2023: "",
            App_2024: "",
            Reset_2020: "",
            Reset_2021: "",
            Reset_2022: "",
            Reset_2023: "",
            Reset_2024: "",
            Count_2020: 1,
            Count_2021: 1,
            Count_2022: "",
            Count_2023: "",
            Count_2024: "",
            Total_Count: 2,
            "2025_App?": "Yes",
            Reg_Number: 3456,
            TW_Boost: "",
            Vol_Points: 10
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

      it "returns one proto_record for each DNF" do
        dnf_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :dnf }
        expect(dnf_proto_records.count).to eq(1)
        expect(dnf_proto_records.first[:year]).to eq(2019)
      end

      it "returns one proto_record for each finish" do
        finished_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :finished }
        expect(finished_proto_records.count).to eq(1)
        expect(finished_proto_records.first[:year]).to eq(2024)
      end

      it "returns one proto_record for each current year application" do
        current_year_application_proto_records = proto_records.select do |proto_record|
          proto_record.attributes[:kind] == :lottery_application && proto_record.attributes[:year] == 2025
        end
        expect(current_year_application_proto_records.count).to eq(3)
        expect(current_year_application_proto_records.map { |pr| pr[:external_id]}).to eq([1234, 2345, 3456])
      end

      it "returns one proto_record for each prior year application" do
        prior_year_application_proto_records = proto_records.select do |proto_record|
          proto_record.attributes[:kind] == :lottery_application && proto_record.attributes[:year] < 2025
        end
        expect(prior_year_application_proto_records.count).to eq(8)
        expect(prior_year_application_proto_records.map { |pr| pr[:year]}).to eq([2024, 2023, 2024, 2022, 2024, 2024, 2020, 2021])
      end

      it "returns one proto_record for each reset" do
        reset_proto_records = proto_records.select do |proto_record|
          proto_record.attributes[:kind] == :ticket_reset_legacy
        end
        expect(reset_proto_records.count).to eq(1)
        expect(reset_proto_records.first[:year]).to eq(2024)
      end

      it "returns one proto_record with legacy ticket count for each entrant" do
        reset_proto_records = proto_records.select do |proto_record|
          proto_record.attributes[:kind] == :lottery_ticket_count_legacy
        end
        expect(reset_proto_records.count).to eq(5)
        expect(reset_proto_records.map { |pr| pr[:year] }).to all eq(2025)
        expect(reset_proto_records.map { |pr| pr[:quantity] }).to eq([1,2,2,0,2])
      end

      it "returns one proto_record for each entrant having volunteer points" do
        volunteer_hour_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :volunteer_hours }
        expect(volunteer_hour_proto_records.count).to eq(1)
        proto_record = volunteer_hour_proto_records.first
        expect(proto_record[:quantity]).to eq(10)
      end

      it "returns one proto_record for each entrant having trail work bonus hours" do
        trail_work_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :trail_work_hours }
        expect(trail_work_proto_records.count).to eq(1)
        proto_record = trail_work_proto_records.first
        expect(proto_record[:quantity]).to eq(8)
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
