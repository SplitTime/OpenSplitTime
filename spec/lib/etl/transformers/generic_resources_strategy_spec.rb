require "rails_helper"

RSpec.describe Etl::Transformers::GenericResourcesStrategy do
  subject { Etl::Transformers::GenericResourcesStrategy.new(parsed_structs, options) }

  let(:course) { build_stubbed(:course, id: 10) }
  let(:event) { build_stubbed(:event, id: 1, course: course) }
  let(:proto_records) { subject.transform }
  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }

  describe "#transform" do
    context "when transforming splits" do
      let(:options) { {parent: event, model: :split} }
      let(:parsed_structs) do
        [
          OpenStruct.new(name: "Start", distance: 0, kind: 0, sub_split_bitmap: 1),
          OpenStruct.new(name: "Aid 1", distance: 5, kind: 2, sub_split_bitmap: 65),
          OpenStruct.new(name: "Finish", distance: 10, kind: 1, sub_split_bitmap: 1)
        ]
      end

      it "returns the same number of ProtoRecords as it is given OpenStructs" do
        expect(proto_records.size).to eq(3)
        expect(proto_records.all? { |row| row.is_a?(ProtoRecord) }).to eq(true)
      end

      it "returns rows with effort headers transformed to match the database" do
        expect(first_proto_record.to_h.keys)
            .to match_array(%i[base_name course_id distance_from_start kind sub_split_bitmap])
      end

      it "assigns event.course_id to :course_id" do
        expect(proto_records.map { |pr| pr[:course_id] }).to all eq(event.course_id)
      end

      it "converts [:distance] from preferred units to meters" do
        expect(proto_records.map { |pr| pr[:distance_from_start] }).to eq([0, 8047, 16_093])
      end
    end

    context "when transforming efforts" do
      let(:effort_1) { temp_efforts.first }
      let(:effort_2) { temp_efforts.second }

      let(:options) { {parent: event, model: :effort} }
      let(:temp_efforts) { build_stubbed_list(:effort, 2, :with_birthdate) }
      let(:parsed_structs) do
        [
          OpenStruct.new(first: effort_1.first_name, last: effort_1.last_name, sex: effort_1.gender, birthdate: effort_1.birthdate, State: "Colorado"),
          OpenStruct.new(first: effort_2.first_name, last: effort_2.last_name, sex: effort_2.gender, birthdate: effort_2.birthdate, State: "New York")
        ]
      end

      it "returns the same number of ProtoRecords as it is given OpenStructs" do
        expect(proto_records.size).to eq(2)
        expect(proto_records.all? { |row| row.is_a?(ProtoRecord) }).to eq(true)
      end

      it "returns rows with effort headers transformed to match the database" do
        expect(first_proto_record.to_h.keys)
            .to match_array(%i[first_name last_name gender birthdate state_code country_code event_id scheduled_start_time])
      end

      it "assigns event.id to :event_id" do
        expect(proto_records.map { |pr| pr[:event_id] }).to all eq(event.id)
      end

      context "when age is provided instead of birthdate" do
        let(:parsed_structs) do
          [
            OpenStruct.new(first: effort_1.first_name, last: effort_1.last_name, sex: effort_1.gender, age: 30, State: "Colorado"),
            OpenStruct.new(first: effort_2.first_name, last: effort_2.last_name, sex: effort_2.gender, age: 42, State: "New York")
          ]
        end

        it "assigns age to :age" do
          expect(proto_records.map { |pr| pr[:age] }).to match_array([30, 42])
        end
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
end
