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

  describe "#transform" do
    # Build some stubbed people just for convenience in assigning attributes to parsed structs
    let(:person_1) { temp_people.first }
    let(:person_2) { temp_people.second }
    let(:temp_people) { build_list(:person, 2) }

    let(:parsed_structs) { [
      OpenStruct.new(first: person_1.first_name, last: person_1.last_name, sex: person_1.gender, State: "Colorado", number_of_tickets: 4, Division: "Fast People"),
      OpenStruct.new(first: person_2.first_name, last: person_2.last_name, sex: person_2.gender, state: "New York", number_of_tickets: 1, division: "slow people"),
    ] }

    let(:options) { {parent: parent} }
    let(:parent) { lottery }

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
  end

  context "when a parent is not provided" do
    let(:parsed_structs) { [] }
    let(:options) { {} }

    it "returns nil and adds an error" do
      expect(proto_records).to be_nil
      expect(subject.errors.size).to eq(1)
      expect(subject.errors.first[:title]).to match(/Parent is missing/)
    end
  end
end
