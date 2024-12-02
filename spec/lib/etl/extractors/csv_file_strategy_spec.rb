# frozen_string_literal: true

require "rails_helper"

RSpec.describe ETL::Extractors::CsvFileStrategy do
  subject { ETL::Extractors::CsvFileStrategy.new(file, options) }
  let(:options) { {} }

  describe "#extract" do
    let(:raw_data) { subject.extract }

    context "when UTF-8 file is provided" do
      let(:file) { file_fixture("test_efforts_utf_8.csv") }

      it "returns raw data in OpenStruct format" do
        expect(subject.errors).to eq([])
        expect(raw_data.size).to eq(3)
        expect(raw_data).to all be_a(OpenStruct)
      end
    end

    context "when ASCII file is provided" do
      let(:file) { file_fixture("test_efforts_ascii.csv") }

      it "returns raw data in OpenStruct format" do
        expect(subject.errors).to eq([])
        expect(raw_data.size).to eq(3)
        expect(raw_data).to all be_a(OpenStruct)
      end
    end

    context "when an ultrasignup efforts file is provided" do
      let(:file) { file_fixture("ultrasignup_efforts.csv") }
      let(:expected_array) do
        [:Order_ID, :Registration_Date, :distance, :Quantity, :Price, :Price_Option, :order_type, :Coupon, :First_Name, :Last_Name, :gender,
         :Identified_Gender, :Age, :AgeGroup, :DOB, :Email, :Address, :City, :State, :Zip, :Country, :Phone, :Removed, :Bib, :Captain, :team_name,
         :emergency_name, :emergency_phone, :statement_id, :item_discount, :order_tax, :ultrasignup_fee, :order_total, :BBQ_Ticket_Meat_9,
         :BBQ_Ticket_Veggie_9, :Race_logo_20, :Mens_Large_15, :Mens_Large_20, :Mens_Medium_15, :Mens_Medium_20, :Mens_Small_15, :Mens_Small_20,
         :Mens_XLarge_15, :Mens_XLarge_20, :Mens_XXL_15, :One_Size_25, :Sticker_3, :Unisex_2XL_35, :Unisex_Large_35, :Unisex_Medium_35,
         :Unisex_Small_35, :Unisex_XL_35, :Womens_Large_15, :Womens_Large_20, :Womens_Medium_15, :Womens_Medium_20, :Womens_Small_15,
         :Womens_Small_20, :Womens_XLarge_15, :Womens_XLarge_20, :Announcer_Notes, :BBQ_Preference, :Is_this_your_first_attempt_at_this_distance,
         :Shirt_Size, :What_name_would_you_like_printed_on_your_bib]
      end

      it "returns raw data in OpenStruct format with expected keys" do
        expect(subject.errors).to be_empty
        expect(raw_data.size).to eq(2)
        expect(raw_data).to all be_a(OpenStruct)

        record = raw_data.first.to_h
        expect(record.keys).to match_array(expected_array)
      end
    end

    context "when a hardrock historical facts file is provided" do
      let(:file) { file_fixture("hardrock_historical_facts.csv") }
      let(:expected_array) do
        [:First, :Last, :Gender,
         :"1992", :"1993", :"1994", :"1996", :"1997", :"1998", :"1999", :"2000", :"2001", :"2003", :"2004", :"2005", :"2006", :"2007", :"2008",
         :"2009", :"2010", :"2011", :"2012", :"2013", :"2014", :"2015", :"2016", :"2017", :"2018", :"2019", :"2021", :"2022", :"2023", :"2024",
         :Which_Lottery?, :Total_DNFs, :DNFs_before_2021, :Total_Finishes, :"#_F_tickets",
         :DNS_since_1992, :DNS_since_1993, :DNS_since_1994, :DNS_since_1996, :DNS_since_1997, :DNS_since_1998, :DNS_since_1999, :DNS_since_2000,
         :DNS_since_2001, :DNS_since_2003, :DNS_since_2004, :DNS_since_2005, :DNS_since_2006, :DNS_since_2007, :DNS_since_2008, :DNS_since_2009,
         :DNS_since_2010, :DNS_since_2011, :DNS_since_2012, :DNS_since_2013, :DNS_since_2014, :DNS_since_2015, :DNS_since_2016, :DNS_since_2017,
         :DNS_since_2018, :DNS_since_2019, :DNS_since_2021, :DNS_since_2022, :DNS_since_2023, :DNS_since_2024,
         :"#_DNS_since_last_start", :"#_DNS_ever", :"Tickets_for_#_DNS_(and_Service_if_Never)", :"#_Trail_work/Course_Sweep/AS_captain_ticks",
         :"#_Service_tickets", :Total_tickets, :"1_=_entered", :First_time_entrant, :"1_=_Selected", :Wait_List_Order, :"2024_Qualifier",
         :Years_Volunteering, :Total_Finished_Tickets, :Total_Never_tickets, :Male_Finished_Tickets, :Male_Never_Tickets, :Female_Finished_Tickets,
         :Female_Never_Tickets, :DOB, :email_address, :Street_Address, :City, :State, :Country, :"Phone_#", :Previous_names_applied_under,
         :Emergency_Contact, :Emergency_Phone, :"#_Years_Vol_Claimed", :Vol_Diff, :"#_Years_Claimed_Applied_in_Past", :Have_you_ever_finished_Hardrock?,
         :"Diff_#DNS", :Already_in_the_spread_sheet, :Removed?, :Description_of_service]
      end

      it "returns raw data in OpenStruct format with expected keys" do
        expect(subject.errors).to be_empty
        expect(raw_data.size).to eq(11)
        expect(raw_data).to all be_a(OpenStruct)

        record = raw_data.first.to_h
        expect(record.keys).to match_array(expected_array)
      end
    end

    context "when an ultrasignup historical facts file is provided" do
      let(:file) { file_fixture("ultrasignup_historical_facts.csv") }
      let(:expected_array) do
        [
          :Order_ID, :First_Name, :Last_Name, :gender, :DOB, :Email, :Address, :City, :State, :Country, :Phone, :emergency_name, :emergency_phone,
          :Volunteer_description, :Ever_finished, :Previous_names_1, :Previous_names_2, :DNS_since_finish, :Qualifier, :Years_volunteered,
        ]
      end

      it "returns raw data in OpenStruct format with expected keys" do
        expect(subject.errors).to be_empty
        expect(raw_data.size).to eq(8)
        expect(raw_data).to all be_a(OpenStruct)

        record = raw_data.first.to_h
        expect(record.keys).to match_array(expected_array)
      end
    end

    context "when a raw ultrasignup participants file is provided" do
      let(:file) { file_fixture("ultrasignup_raw_participant_export.csv") }
      let(:expected_array) do
        [:Order_ID, :Registration_Date, :distance, :Quantity, :Price, :Price_Option, :order_type, :Coupon, :First_Name, :Last_Name, :gender,
         :Identified_Gender, :Age, :AgeGroup, :DOB, :Email, :Address, :City, :State, :Zip, :Country, :Phone, :Removed, :Bib, :Captain,
         :team_name, :emergency_name, :emergency_phone, :statement_id, :item_discount, :order_tax, :ultrasignup_fee, :order_total,
         :Donation_10, :Donation_100, :Donation_25, :Donation_250, :Donation_50, :Description_of_Hardrock_volunteering, :Have_you_ever_finished_the_Hardrock_100,
         :Livestream_Consent, :Name_verification, :Name_Verification_for_Hardrock, :Name_Verification_for_Qualifier,
         :Past_applications_since_running_Hardrock, :Please_select_the_qualifier_you_finished_duplicate,
         :"Please_select_the_qualifier_you_finished.", :"Please_select_the_qualifier_you_finished._2",
         :Refund_Policy, :Service_Requirement, :Shirt_Size, :Years_volunteered]
      end

      it "returns raw data in OpenStruct format with expected keys" do
        expect(subject.errors).to be_empty
        expect(raw_data.size).to eq(2)
        expect(raw_data).to all be_a(OpenStruct)

        record = raw_data.first.to_h
        expect(record.keys).to match_array(expected_array)
      end
    end

    context "when file has extra empty lines" do
      let(:file) { file_fixture("test_efforts_empty_lines.csv") }

      it "returns raw data in OpenStruct format ignoring empty lines" do
        expect(subject.errors).to eq([])
        expect(raw_data.size).to eq(3)
        expect(raw_data).to all be_a(OpenStruct)
      end
    end

    context "when file is not provided" do
      let(:file) { nil }

      it "returns nil" do
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to match(/File not found/)
      end
    end

    context "when the file has a single column" do
      let(:file) { file_fixture("single_column.csv") }

      it "does not return errors" do
        subject.extract

        expect(subject.errors).to be_empty
      end

      it "returns headers converted to symbols" do
        expect(raw_data.first.to_h.keys).to eq([:Order_ID])
      end

      it "returns expected parsed structs" do
        expect(raw_data.map { |struct| struct[:Order_ID] }).to match_array([123, 456, 789])
      end
    end

    context "when the file has non-standard characters in headers" do
      let(:file) { file_fixture("test_efforts_header_formats.csv") }

      it "returns headers converted to symbols" do
        expect(raw_data.first.to_h.keys).to eq([:first_name, :LAST, :sex, :age, :city, :state, :country, :'bib_#'])
      end
    end

    context "when the file has an extension that is not .csv" do
      let(:file) { file_fixture("test_track.gpx") }

      it "returns nil and reports an error" do
        expect(raw_data).to be_nil
        expect(subject.errors.first[:title]).to eq("File type incorrect")
      end
    end

    context "when the file causes a CSV parsing error" do
      let(:file) { file_fixture("test_efforts_duplicate_headers.csv") }

      it "returns an empty array and reports the error" do
        expect(raw_data).to eq([])

        error = subject.errors.first
        expect(error[:title]).to eq("CSV error")
        expect(error[:detail][:messages]).to include('Duplicate Headers in CSV: {"country"=>2}')
      end
    end
  end
end
