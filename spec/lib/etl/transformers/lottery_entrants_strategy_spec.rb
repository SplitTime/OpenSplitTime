# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::ETL::Transformers::LotteryEntrantsStrategy do
  subject { described_class.new(parsed_structs, options) }

  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:fast_division) { lottery.divisions.find_by(name: "Fast People") }
  let(:slow_division) { lottery.divisions.find_by(name: "Slow People") }
  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }

  # Build some stubbed people just for convenience in assigning attributes to parsed structs
  let(:person_1) { temp_people.first }
  let(:person_2) { temp_people.second }
  let(:temp_people) { build_list(:person, 2) }

  let(:parsed_structs) { [
    OpenStruct.new(first: person_1.first_name, last: person_1.last_name, sex: person_1.gender, State: "Colorado", country: "US", Tickets: 4, Division: division_name_1),
    OpenStruct.new(first: person_2.first_name, last: person_2.last_name, sex: person_2.gender, state: "NY", number_of_tickets: 1, division: division_name_2),
  ] }

  let(:division_name_1) { "Fast People" }
  let(:division_name_2) { "slow people" }

  let(:options) { {parent: parent} }
  let(:parent) { lottery }

  describe "#transform" do
    it "returns the same number of ProtoRecords as it is given OpenStructs" do
      expect(proto_records.size).to eq(2)
      expect(proto_records).to all be_a(ProtoRecord)
    end

    it "returns rows with effort headers transformed to match the lottery entrant schema" do
      expect(first_proto_record.to_h.keys)
        .to match_array(%i(first_name last_name gender state_code country_code number_of_tickets lottery_division_id))
    end

    it "assigns the expected divisions" do
      expect(proto_records.first[:lottery_division_id]).to eq(fast_division.id)
      expect(proto_records.second[:lottery_division_id]).to eq(slow_division.id)
    end

    it "assigns other attributes" do
      expect(first_proto_record[:first_name]).to eq(person_1.first_name)
      expect(first_proto_record[:last_name]).to eq(person_1.last_name)
      expect(first_proto_record[:gender]).to eq(person_1.gender)
      expect(first_proto_record[:state_code]).to eq("CO")
      expect(first_proto_record[:country_code]).to eq("US")
      expect(first_proto_record[:number_of_tickets]).to eq(4)

      expect(second_proto_record[:first_name]).to eq(person_2.first_name)
      expect(second_proto_record[:last_name]).to eq(person_2.last_name)
      expect(second_proto_record[:gender]).to eq(person_2.gender)
      expect(second_proto_record[:state_code]).to eq("NY")
      expect(second_proto_record[:country_code]).to eq("US")
      expect(second_proto_record[:number_of_tickets]).to eq(1)
    end

    it "does not return errors" do
      expect(subject.errors).to be_empty
    end

    context "when the transform fails" do
      before { allow_any_instance_of(::ProtoRecord).to receive(:transform_as).and_raise NoMethodError, "No method #xyz for proto record" }
      it "returns proto records (which will be in an untransformed or partially transformed state)" do
        expect(proto_records.size).to eq(2)
      end

      it "returns descriptive errors" do
        subject.transform
        expect(subject.errors).to be_present
        expect(subject.errors.first.dig(:detail, :messages).first).to match /Transform failed for row 1:/
        expect(subject.errors.second.dig(:detail, :messages).first).to match /Transform failed for row 2:/
      end
    end

    context "when a division is not found" do
      let(:division_name_1) { "Nonexistent Division" }
      it "does not transform the proto record with the unknown division" do
        expect(first_proto_record[:lotter_division_id]).to be_nil
      end

      it "transforms the other proto records" do
        expect(second_proto_record[:lottery_division_id]).to eq(slow_division.id)
      end

      it "returns a descriptive error" do
        subject.transform
        expect(subject.errors).to be_present
        expect(subject.errors.first.dig(:detail, :messages).first).to match /Division could not be found for row 1:/
      end
    end

    context "when a parent is not provided" do
      let(:options) { {} }

      it "returns untransformed proto records" do
        expect(proto_records.size).to eq(2)
      end

      it "adds a descriptive error" do
        expect(subject.errors.size).to eq(1)
        expect(subject.errors.first[:title]).to match /Parent is missing/
      end
    end
  end
end
