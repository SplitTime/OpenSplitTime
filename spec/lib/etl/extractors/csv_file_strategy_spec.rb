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

    context "when an ultrasignup file is provided" do
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
