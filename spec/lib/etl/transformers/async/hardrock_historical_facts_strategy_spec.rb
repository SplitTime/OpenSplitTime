# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::Transformers::Async::HardrockHistoricalFactsStrategy do
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
            :First => "Antony",
            :Last => "Grady",
            :Gender => "M",
            :"1992" => "",
            :"1993" => "",
            :"1994" => "",
            :"1996" => "",
            :"1997" => "",
            :"1998" => "",
            :"1999" => "",
            :"2000" => "",
            :"2001" => "",
            :"2003" => "",
            :"2004" => "",
            :"2005" => "",
            :"2006" => "",
            :"2007" => "",
            :"2008" => "",
            :"2009" => "",
            :"2010" => "",
            :"2011" => "",
            :"2012" => "",
            :"2013" => "",
            :"2014" => "",
            :"2015" => "",
            :"2016" => "",
            :"2017" => "",
            :"2018" => "",
            :"2019" => "DNS",
            :"2021" => "",
            :"2022" => "",
            :"2023" => "",
            :"2024" => "",
            :Which_Lottery? => "Never",
            :Total_DNFs => 0,
            :DNFs_before_2021 => 0,
            :Total_Finishes => 0,
            :"#_F_tickets" => 0,
            :DNS_since_1992 => 1,
            :DNS_since_1993 => 1,
            :DNS_since_1994 => 1,
            :DNS_since_1996 => 1,
            :DNS_since_1997 => 1,
            :DNS_since_1998 => 1,
            :DNS_since_1999 => 1,
            :DNS_since_2000 => 1,
            :DNS_since_2001 => 1,
            :DNS_since_2003 => 1,
            :DNS_since_2004 => 1,
            :DNS_since_2005 => 1,
            :DNS_since_2006 => 1,
            :DNS_since_2007 => 1,
            :DNS_since_2008 => 1,
            :DNS_since_2009 => 1,
            :DNS_since_2010 => 1,
            :DNS_since_2011 => 1,
            :DNS_since_2012 => 1,
            :DNS_since_2013 => 1,
            :DNS_since_2014 => 1,
            :DNS_since_2015 => 1,
            :DNS_since_2016 => 1,
            :DNS_since_2017 => 1,
            :DNS_since_2018 => 1,
            :DNS_since_2019 => 1,
            :DNS_since_2021 => 0,
            :DNS_since_2022 => 0,
            :DNS_since_2023 => 0,
            :DNS_since_2024 => 0,
            :"#_DNS_since_last_start" => 1,
            :"#_DNS_ever" => 1,
            :"Tickets_for_#_DNS_(and_Service_if_Never)" => 2,
            :"#_Trail_work/Course_Sweep/AS_captain_ticks" => "",
            :"#_Service_tickets" => 0,
            :Total_tickets => 2,
            :"1_=_entered" => "",
            :First_time_entrant => "",
            :"1_=_Selected" => "",
            :Wait_List_Order => "",
            :"2024_Qualifier" => "2023 SEPT: Grindstone 100 Mile",
            :Years_Volunteering => "",
            :Total_Finished_Tickets => 0,
            :Total_Never_tickets => 0,
            :Male_Finished_Tickets => 0,
            :Male_Never_Tickets => 0,
            :Female_Finished_Tickets => 0,
            :Female_Never_Tickets => 0,
            :DOB => "",
            :email_address => "dominica@rau.info",
            :Street_Address => "7332 Kassulke Skyway",
            :City => "Bednarshire",
            :State => "VA",
            :Country => "USA",
            :"Phone_#" => 7797152514,
            :Previous_names_applied_under => "No",
            :Emergency_Contact => nil,
            :Emergency_Phone => nil,
            :"#_Years_Vol_Claimed" => 0,
            :Vol_Diff => 0,
            :"#_Years_Claimed_Applied_in_Past" => "",
            :Have_you_ever_finished_Hardrock? => "",
            :"Diff_#DNS" => "",
            :Already_in_the_spread_sheet => 1,
            :Removed? => "",
            :Description_of_service => ""
          ),
          OpenStruct.new(
            :First => "Beryl",
            :Last => "Kutch",
            :Gender => "F",
            :"1992" => "",
            :"1993" => "",
            :"1994" => "",
            :"1996" => "",
            :"1997" => "",
            :"1998" => "",
            :"1999" => "",
            :"2000" => "",
            :"2001" => "",
            :"2003" => "",
            :"2004" => "",
            :"2005" => "",
            :"2006" => "",
            :"2007" => "",
            :"2008" => "",
            :"2009" => "",
            :"2010" => "",
            :"2011" => "",
            :"2012" => "",
            :"2013" => "",
            :"2014" => "",
            :"2015" => "",
            :"2016" => "DNS",
            :"2017" => "DNS",
            :"2018" => "DNS",
            :"2019" => "DNS",
            :"2021" => "",
            :"2022" => "",
            :"2023" => "",
            :"2024" => "",
            :Which_Lottery? => "Never",
            :Total_DNFs => 0,
            :DNFs_before_2021 => 0,
            :Total_Finishes => 0,
            :"#_F_tickets" => 0,
            :DNS_since_1992 => 4,
            :DNS_since_1993 => 4,
            :DNS_since_1994 => 4,
            :DNS_since_1996 => 4,
            :DNS_since_1997 => 4,
            :DNS_since_1998 => 4,
            :DNS_since_1999 => 4,
            :DNS_since_2000 => 4,
            :DNS_since_2001 => 4,
            :DNS_since_2003 => 4,
            :DNS_since_2004 => 4,
            :DNS_since_2005 => 4,
            :DNS_since_2006 => 4,
            :DNS_since_2007 => 4,
            :DNS_since_2008 => 4,
            :DNS_since_2009 => 4,
            :DNS_since_2010 => 4,
            :DNS_since_2011 => 4,
            :DNS_since_2012 => 4,
            :DNS_since_2013 => 4,
            :DNS_since_2014 => 4,
            :DNS_since_2015 => 4,
            :DNS_since_2016 => 4,
            :DNS_since_2017 => 3,
            :DNS_since_2018 => 2,
            :DNS_since_2019 => 1,
            :DNS_since_2021 => 0,
            :DNS_since_2022 => 0,
            :DNS_since_2023 => 0,
            :DNS_since_2024 => 0,
            :"#_DNS_since_last_start" => 4,
            :"#_DNS_ever" => 4,
            :"Tickets_for_#_DNS_(and_Service_if_Never)" => 16,
            :"#_Trail_work/Course_Sweep/AS_captain_ticks" => "",
            :"#_Service_tickets" => 0,
            :Total_tickets => 16,
            :"1_=_entered" => "",
            :First_time_entrant => "",
            :"1_=_Selected" => "",
            :Wait_List_Order => "",
            :"2024_Qualifier" => "2023 SEPT: Bear 100",
            :Years_Volunteering => 0,
            :Total_Finished_Tickets => 0,
            :Total_Never_tickets => 0,
            :Male_Finished_Tickets => 0,
            :Male_Never_Tickets => 0,
            :Female_Finished_Tickets => 0,
            :Female_Never_Tickets => 0,
            :DOB => "",
            :email_address => "candra@thiel.name",
            :Street_Address => "94813 Swaniawski Ranch",
            :City => "Littleberg",
            :State => "NOR",
            :Country => "NOR",
            :"Phone_#" => 4747239760,
            :Previous_names_applied_under => "N/A",
            :Emergency_Contact => "Shellie Krajcik",
            :Emergency_Phone => 4747239722,
            :"#_Years_Vol_Claimed" => 0,
            :Vol_Diff => 0,
            :"#_Years_Claimed_Applied_in_Past" => "",
            :Have_you_ever_finished_Hardrock? => "",
            :"Diff_#DNS" => "",
            :Already_in_the_spread_sheet => 1,
            :Removed? => "",
            :Description_of_service => ""
          ),
          OpenStruct.new(
            :First => "Dorothy",
            :Last => "Fahey",
            :Gender => "F",
            :"1992" => "",
            :"1993" => "",
            :"1994" => "",
            :"1996" => "",
            :"1997" => "",
            :"1998" => "",
            :"1999" => "",
            :"2000" => "",
            :"2001" => "",
            :"2003" => "",
            :"2004" => "",
            :"2005" => "",
            :"2006" => "",
            :"2007" => "",
            :"2008" => "",
            :"2009" => "",
            :"2010" => "",
            :"2011" => "",
            :"2012" => "",
            :"2013" => "",
            :"2014" => "",
            :"2015" => "DNS",
            :"2016" => "DNS",
            :"2017" => "",
            :"2018" => "",
            :"2019" => "",
            :"2021" => "",
            :"2022" => "",
            :"2023" => "",
            :"2024" => "",
            :Which_Lottery? => "Never",
            :Total_DNFs => 0,
            :DNFs_before_2021 => 0,
            :Total_Finishes => 0,
            :"#_F_tickets" => 0,
            :DNS_since_1992 => 2,
            :DNS_since_1993 => 2,
            :DNS_since_1994 => 2,
            :DNS_since_1996 => 2,
            :DNS_since_1997 => 2,
            :DNS_since_1998 => 2,
            :DNS_since_1999 => 2,
            :DNS_since_2000 => 2,
            :DNS_since_2001 => 2,
            :DNS_since_2003 => 2,
            :DNS_since_2004 => 2,
            :DNS_since_2005 => 2,
            :DNS_since_2006 => 2,
            :DNS_since_2007 => 2,
            :DNS_since_2008 => 2,
            :DNS_since_2009 => 2,
            :DNS_since_2010 => 2,
            :DNS_since_2011 => 2,
            :DNS_since_2012 => 2,
            :DNS_since_2013 => 2,
            :DNS_since_2014 => 2,
            :DNS_since_2015 => 2,
            :DNS_since_2016 => 1,
            :DNS_since_2017 => 0,
            :DNS_since_2018 => 0,
            :DNS_since_2019 => 0,
            :DNS_since_2021 => 0,
            :DNS_since_2022 => 0,
            :DNS_since_2023 => 0,
            :DNS_since_2024 => 0,
            :"#_DNS_since_last_start" => 2,
            :"#_DNS_ever" => 2,
            :"Tickets_for_#_DNS_(and_Service_if_Never)" => 4,
            :"#_Trail_work/Course_Sweep/AS_captain_ticks" => "",
            :"#_Service_tickets" => 0,
            :Total_tickets => 4,
            :"1_=_entered" => "",
            :First_time_entrant => "",
            :"1_=_Selected" => "",
            :Wait_List_Order => "",
            :"2024_Qualifier" => "",
            :Years_Volunteering => 0,
            :Total_Finished_Tickets => 0,
            :Total_Never_tickets => 0,
            :Male_Finished_Tickets => 0,
            :Male_Never_Tickets => 0,
            :Female_Finished_Tickets => 0,
            :Female_Never_Tickets => 0,
            :DOB => "",
            :email_address => "alphonso@carterjaskolski.com",
            :Street_Address => "9497 Hirthe Lake",
            :City => "Pfannerstillberg",
            :State => "WA",
            :Country => "USA",
            :"Phone_#" => 8952939469,
            :Previous_names_applied_under => "NA",
            :Emergency_Contact => "Sonja Christiansen",
            :Emergency_Phone => 8615039757,
            :"#_Years_Vol_Claimed" => 0,
            :Vol_Diff => 0,
            :"#_Years_Claimed_Applied_in_Past" => 0,
            :Have_you_ever_finished_Hardrock? => 0,
            :"Diff_#DNS" => "",
            :Already_in_the_spread_sheet => "",
            :Removed? => "",
            :Description_of_service => 1,
            :column_105 => "",
            :column_106 => ""
          ),
          OpenStruct.new(
            :First => "Theresa",
            :Last => "O'Connell",
            :Gender => "F",
            :"1992" => "",
            :"1993" => "",
            :"1994" => "",
            :"1996" => "",
            :"1997" => "",
            :"1998" => "",
            :"1999" => "",
            :"2000" => "",
            :"2001" => "",
            :"2003" => "",
            :"2004" => "",
            :"2005" => "",
            :"2006" => "",
            :"2007" => "",
            :"2008" => "",
            :"2009" => "",
            :"2010" => "",
            :"2011" => "",
            :"2012" => "",
            :"2013" => "",
            :"2014" => "DNF",
            :"2015" => "F",
            :"2016" => "F",
            :"2017" => "DNS",
            :"2018" => "DNS",
            :"2019" => "DNS",
            :"2021" => "DNS",
            :"2022" => "DNS",
            :"2023" => "",
            :"2024" => "",
            :Which_Lottery? => "Else",
            :Total_DNFs => 1,
            :DNFs_before_2021 => 1,
            :Total_Finishes => 2,
            :"#_F_tickets" => 2,
            :DNS_since_1992 => 0,
            :DNS_since_1993 => 0,
            :DNS_since_1994 => 0,
            :DNS_since_1996 => 0,
            :DNS_since_1997 => 0,
            :DNS_since_1998 => 0,
            :DNS_since_1999 => 0,
            :DNS_since_2000 => 0,
            :DNS_since_2001 => 0,
            :DNS_since_2003 => 0,
            :DNS_since_2004 => 0,
            :DNS_since_2005 => 0,
            :DNS_since_2006 => 0,
            :DNS_since_2007 => 0,
            :DNS_since_2008 => 0,
            :DNS_since_2009 => 0,
            :DNS_since_2010 => 0,
            :DNS_since_2011 => 0,
            :DNS_since_2012 => 0,
            :DNS_since_2013 => 0,
            :DNS_since_2014 => 0,
            :DNS_since_2015 => 0,
            :DNS_since_2016 => 0,
            :DNS_since_2017 => 5,
            :DNS_since_2018 => 4,
            :DNS_since_2019 => 3,
            :DNS_since_2021 => 2,
            :DNS_since_2022 => 1,
            :DNS_since_2023 => 0,
            :DNS_since_2024 => 0,
            :"#_DNS_since_last_start" => 5,
            :"#_DNS_ever" => 5,
            :"Tickets_for_#_DNS_(and_Service_if_Never)" => 5,
            :"#_Trail_work/Course_Sweep/AS_captain_ticks" => "",
            :"#_Service_tickets" => 0,
            :Total_tickets => 8,
            :"1_=_entered" => "",
            :First_time_entrant => "",
            :"1_=_Selected" => "",
            :Wait_List_Order => "",
            :"2024_Qualifier" => "",
            :Years_Volunteering => 1,
            :Total_Finished_Tickets => 0,
            :Total_Never_tickets => 0,
            :Male_Finished_Tickets => 0,
            :Male_Never_Tickets => 0,
            :Female_Finished_Tickets => 0,
            :Female_Never_Tickets => 0,
            :DOB => "09/10/1997",
            :email_address => "woodrow@runte.ca",
            :Street_Address => "028 Kunze Freeway",
            :City => "Tamartown",
            :State => "IA",
            :Country => "USA",
            :"Phone_#" => "776-426-2796",
            :Previous_names_applied_under => "Theresa Burley",
            :Emergency_Contact => "",
            :Emergency_Phone => "",
            :"#_Years_Vol_Claimed" => 1,
            :Vol_Diff => 0,
            :"#_Years_Claimed_Applied_in_Past" => "",
            :Have_you_ever_finished_Hardrock? => "",
            :"Diff_#DNS" => "",
            :Already_in_the_spread_sheet => 1,
            :Removed? => "",
            :Description_of_service => "Trail work in 2021",
            :column_105 => nil,
            :column_106 => nil
          )
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

      it "returns one proto_record for each DNS" do
        dns_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :dns }
        expect(dns_proto_records.count).to eq(12)
      end

      it "returns one proto_record for each DNF" do
        dnf_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :dnf }
        expect(dnf_proto_records.count).to eq(1)
      end

      it "returns one proto_record for each finish" do
        finished_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :finished }
        expect(finished_proto_records.count).to eq(2)
      end

      it "returns one proto_record for each legacy volunteer fact" do
        legacy_volunteer_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :volunteer_legacy }
        expect(legacy_volunteer_proto_records.count).to eq(1)
        proto_record = legacy_volunteer_proto_records.first
        expect(proto_record[:quantity]).to eq(1)
        expect(proto_record[:comments]).to eq("Trail work in 2021")
      end

      it "returns one proto_record for each reported 2024 qualifier" do
        reported_qualifier_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :reported_qualifier_finish }
        expect(reported_qualifier_proto_records.count).to eq(2)
        expect(reported_qualifier_proto_records.map { |pr| pr[:comments] }).to match_array(["2023 SEPT: Grindstone 100 Mile", "2023 SEPT: Bear 100"])
      end

      it "returns one proto_record for each provided emergency contact" do
        emergency_contact_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :provided_emergency_contact }
        expect(emergency_contact_proto_records.count).to eq(2)
        expect(emergency_contact_proto_records.map { |pr| pr[:comments] }).to match_array(["Shellie Krajcik, 4747239722", "Sonja Christiansen, 8615039757"])
      end

      it "returns one proto_record for each provided previous name" do
        previous_name_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :provided_previous_name }
        expect(previous_name_proto_records.count).to eq(1)
        expect(previous_name_proto_records.first[:comments]).to eq("Theresa Burley")
      end

      it "returns one proto_record per struct for legacy ticket count" do
        legacy_ticket_count_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :lottery_ticket_count_legacy }
        expect(legacy_ticket_count_proto_records.count).to eq(structs.count)
        expect(legacy_ticket_count_proto_records.map { |pr| pr[:quantity] }).to eq([2, 16, 4, 8])
      end

      it "returns one proto_record per struct for legacy division" do
        legacy_division_proto_records = proto_records.select { |proto_record| proto_record.attributes[:kind] == :lottery_division_legacy }
        expect(legacy_division_proto_records.count).to eq(structs.count)
        expect(legacy_division_proto_records.map { |pr| pr[:comments] }).to eq(["Never", "Never", "Never", "Else"])
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
