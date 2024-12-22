# frozen_string_literal: true

require "rails_helper"

RSpec.describe Etl::Transformers::Async::UltrasignupHistoricalFactsStrategy do
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
            :Registration_Date => "2024-10-05",
            :distance => "100 Mile",
            :Quantity => 1,
            :Price => 200.00,
            :Price_Option => 200.00,
            :order_type => "",
            :Coupon => "",
            :First_Name => "Emanuel",
            :Last_Name => "Nicolas",
            :gender => "M",
            :Identified_Gender => "M",
            :Age => 20,
            :AgeGroup => "",
            :DOB => "2003-12-18",
            :Email => "shea_skiles@steubergreenfelder.name",
            :Address => "7463 Carmella Lakes",
            :City => "North Donna",
            :State => "CO",
            :Zip => 80202,
            :Country => "UZ",
            :Phone => "(796)778-1767 x7154",
            :Removed => "No",
            :Bib => "",
            :Captain => "no",
            :team_name => "",
            :emergency_name => "No",
            :emergency_phone => "NA",
            :statement_id => "",
            :item_discount => "",
            :order_tax => 0.0,
            :ultrasignup_fee => 11.77,
            :order_total => 211.77,
            :Donation_10 => "",
            :Donation_100 => "",
            :Donation_25 => "",
            :Donation_250 => "",
            :Donation_50 => "",
            :Description_of_Hardrock_volunteering => "Cunningham 2021, 2022, 2023",
            :Have_you_ever_finished_the_Hardrock_100 => "No",
            :Livestream_Consent => "Yes",
            :Name_verification => "Yes",
            :Name_Verification_for_Hardrock => "",
            :Name_Verification_for_Qualifier => "",
            :Past_applications_since_running_Hardrock => 3,
            :Please_select_the_qualifier_you_finished_duplicate => "",
            :"Please_select_the_qualifier_you_finished." => "2023 OCT: Diagonale des Fous (Reunion Is)",
            :"Please_select_the_qualifier_you_finished._2" => "",
            :Refund_Policy => "Yes",
            :Service_Requirement => "Yes",
            :Shirt_Size => "M",
            :Years_volunteered => 3
          ),
          OpenStruct.new(
            :Order_ID => 26861,
            :Registration_Date => "2024-10-05",
            :distance => "100 Mile",
            :Quantity => 1,
            :Price => 200.00,
            :Price_Option => 200.00,
            :order_type => "",
            :Coupon => "",
            :First_Name => "Dave",
            :Last_Name => "Conroy",
            :gender => "M",
            :Identified_Gender => "M",
            :Age => 20,
            :AgeGroup => "",
            :DOB => "1973-07-11",
            :Email => "zulema@satterfield.name",
            :Address => "14181 Calvin Cove",
            :City => "Zacktown",
            :State => "MS",
            :Zip => 80202,
            :Country => "DE",
            :Phone => "453-682-9576",
            :Removed => "No",
            :Bib => "",
            :Captain => "no",
            :team_name => "",
            :emergency_name => "Carleen Paucek",
            :emergency_phone => "None",
            :statement_id => "",
            :item_discount => "",
            :order_tax => 0.0,
            :ultrasignup_fee => 11.77,
            :order_total => 211.77,
            :Donation_10 => "",
            :Donation_100 => "",
            :Donation_25 => "",
            :Donation_250 => "",
            :Donation_50 => "",
            :Description_of_Hardrock_volunteering => "",
            :Have_you_ever_finished_the_Hardrock_100 => "No",
            :Livestream_Consent => "Yes",
            :Name_verification => "Yes",
            :Name_Verification_for_Hardrock => "David Conroy",
            :Name_Verification_for_Qualifier => "david conroy",
            :Past_applications_since_running_Hardrock => 1,
            :Please_select_the_qualifier_you_finished_duplicate => "",
            :"Please_select_the_qualifier_you_finished." => "2023 AUG: Bigfoot 200",
            :"Please_select_the_qualifier_you_finished._2" => "",
            :Refund_Policy => "Yes",
            :Service_Requirement => "Yes",
            :Shirt_Size => "M",
            :Years_volunteered => 0
          ),
          OpenStruct.new(
            :Order_ID => 26868,
            :Registration_Date => "2024-10-05",
            :distance => "100 Mile",
            :Quantity => 1,
            :Price => 200.00,
            :Price_Option => 200.00,
            :order_type => "",
            :Coupon => "",
            :First_Name => "Louis",
            :Last_Name => "Benoit",
            :gender => "M",
            :Identified_Gender => "M",
            :Age => 20,
            :AgeGroup => "",
            :DOB => "04/22/1993",
            :Email => "louis@gmail.com",
            :Address => "678 Allée du bois",
            :City => "ARNAS",
            :State => "",
            :Zip => 80202,
            :Country => "FRA",
            :Phone => 33688547410,
            :Removed => "No",
            :Bib => "",
            :Captain => "no",
            :team_name => "",
            :emergency_name => "Françoise Benoit",
            :emergency_phone => 33682847631,
            :statement_id => "",
            :item_discount => "",
            :order_tax => 0.0,
            :ultrasignup_fee => 11.77,
            :order_total => 211.77,
            :Donation_10 => "",
            :Donation_100 => "",
            :Donation_25 => "",
            :Donation_250 => "",
            :Donation_50 => "",
            :Description_of_Hardrock_volunteering => "",
            :Have_you_ever_finished_the_Hardrock_100 => "No",
            :Livestream_Consent => "Yes",
            :Name_verification => "Yes",
            :Name_Verification_for_Hardrock => "louis benoit",
            :Name_Verification_for_Qualifier => "",
            :Past_applications_since_running_Hardrock => 0,
            :Please_select_the_qualifier_you_finished_duplicate => "",
            :"Please_select_the_qualifier_you_finished." => "2023 SEPT: Tor de Geants (Italy)",
            :"Please_select_the_qualifier_you_finished._2" => "",
            :Refund_Policy => "Yes",
            :Service_Requirement => "Yes",
            :Shirt_Size => "M",
            :Years_volunteered => 0
          ),
          OpenStruct.new(
            :Order_ID => 26891,
            :Registration_Date => "2024-10-05",
            :distance => "100 Mile",
            :Quantity => 1,
            :Price => 200.00,
            :Price_Option => 200.00,
            :order_type => "",
            :Coupon => "",
            :First_Name => "Marie",
            :Last_Name => "Sanjust",
            :gender => "F",
            :Identified_Gender => "M",
            :Age => 20,
            :AgeGroup => "",
            :DOB => "07/07/1999",
            :Email => "marie@gmail.com",
            :Address => "54 Majestic Valley Road, Aneia",
            :City => "Johannesburg",
            :State => "Gauteng",
            :Zip => 80202,
            :Country => "ZAF",
            :Phone => 27833123123,
            :Removed => "No",
            :Bib => "",
            :Captain => "no",
            :team_name => "",
            :emergency_name => "Promo",
            :emergency_phone => 27724373177,
            :statement_id => "",
            :item_discount => "",
            :order_tax => 0.0,
            :ultrasignup_fee => 11.77,
            :order_total => 211.77,
            :Donation_10 => "",
            :Donation_100 => "",
            :Donation_25 => "",
            :Donation_250 => "",
            :Donation_50 => "",
            :Description_of_Hardrock_volunteering => "",
            :Have_you_ever_finished_the_Hardrock_100 => "Yes",
            :Livestream_Consent => "Yes",
            :Name_verification => "Yes",
            :Name_Verification_for_Hardrock => "Marie Antoinette",
            :Name_Verification_for_Qualifier => "Maria Sanjust",
            :Past_applications_since_running_Hardrock => 0,
            :Please_select_the_qualifier_you_finished_duplicate => "",
            :"Please_select_the_qualifier_you_finished." => "2023 Nov: Ultra-Trail Cape Town",
            :"Please_select_the_qualifier_you_finished._2" => "",
            :Refund_Policy => "Yes",
            :Service_Requirement => "Yes",
            :Shirt_Size => "M",
            :Years_volunteered => 0
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

      it "returns one proto_record for each multi-year volunteer fact" do
        volunteer_multi_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :volunteer_multi_reported }
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
