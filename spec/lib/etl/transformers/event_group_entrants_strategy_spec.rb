# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::ETL::Transformers::EventGroupEntrantsStrategy do
  subject { described_class.new(parsed_structs, options) }

  let(:proto_records) { subject.transform }

  let(:first_proto_record) { proto_records.first }
  let(:second_proto_record) { proto_records.second }
  let(:third_proto_record) { proto_records.third }

  # Build some stubbed people just for convenience in assigning attributes to parsed structs
  let(:person_1) { temp_people.first }
  let(:person_2) { temp_people.second }
  let(:temp_people) { build_list(:person, 2) }

  let(:parsed_structs) do
    [
      OpenStruct.new(first: person_1.first_name, last: person_1.last_name, sex: person_1.gender, bib_number: 12, State: "Colorado", country: "US", Event_name: struct_1_event_name),
      OpenStruct.new(first: person_2.first_name, last: person_2.last_name, sex: person_2.gender, bib_number: 13, state: "NY", event_name: struct_2_event_name)
    ]
  end

  let(:options) { {parent: parent, import_job: import_job} }
  let(:parent) { event_group }
  let(:import_job) { create(:import_job, parent_type: "EventGroup", parent_id: event_group.id, format: :event_group_entrants) }

  describe "#transform" do
    let(:expected_schema) do
      [
        :first_name,
        :last_name,
        :gender,
        :bib_number,
        :state_code,
        :country_code,
        :scheduled_start_time,
        :event_id,
      ]
    end

    context "in an event group with multiple events" do
      let(:event_group) { event_groups(:rufa_2017) }
      let(:event_24_hour) { event_group.events.find_by(short_name: "24H") }
      let(:event_12_hour) { event_group.events.find_by(short_name: "12H") }

      let(:struct_1_event_name) { "24H" }
      let(:struct_2_event_name) { "12H" }

      it "returns the same number of ProtoRecords as it is given OpenStructs" do
        expect(proto_records.size).to eq(2)
        expect(proto_records).to all be_a(ProtoRecord)
      end

      it "returns rows with effort headers transformed to match the effort schema" do
        expect(first_proto_record.to_h.keys).to match_array(expected_schema)
      end

      it "assigns the expected events" do
        expect(proto_records.first[:event_id]).to eq(event_24_hour.id)
        expect(proto_records.second[:event_id]).to eq(event_12_hour.id)
      end

      it "assigns other attributes" do
        expect(first_proto_record[:first_name]).to eq(person_1.first_name)
        expect(first_proto_record[:last_name]).to eq(person_1.last_name)
        expect(first_proto_record[:gender]).to eq(person_1.gender)
        expect(first_proto_record[:state_code]).to eq("CO")
        expect(first_proto_record[:country_code]).to eq("US")
        expect(first_proto_record[:bib_number]).to eq(12)

        expect(second_proto_record[:first_name]).to eq(person_2.first_name)
        expect(second_proto_record[:last_name]).to eq(person_2.last_name)
        expect(second_proto_record[:gender]).to eq(person_2.gender)
        expect(second_proto_record[:state_code]).to eq("NY")
        expect(second_proto_record[:country_code]).to eq("US")
        expect(second_proto_record[:bib_number]).to eq(13)
      end

      it "deletes the event_name attribute" do
        expect(first_proto_record).not_to have_key(:event_name)
        expect(second_proto_record).not_to have_key(:event_name)
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
          expect(subject.errors.first.dig(:detail, :messages).first).to match(/Transform failed:/)
          expect(subject.errors.first.dig(:detail, :row_index)).to eq(1)
          expect(subject.errors.second.dig(:detail, :messages).first).to match(/Transform failed:/)
          expect(subject.errors.second.dig(:detail, :row_index)).to eq(2)
        end

        it "sets failure count on the import job" do
          subject.transform
          expect(import_job.failure_count).to eq(2)
        end
      end

      context "when a division is not found" do
        let(:struct_1_event_name) { "Nonexistent Event" }
        it "does not transform the proto record with the unknown division" do
          expect(first_proto_record[:event_id]).to be_nil
        end

        it "transforms the other proto records" do
          expect(second_proto_record[:event_id]).to eq(event_12_hour.id)
        end

        it "returns a descriptive error" do
          subject.transform
          expect(subject.errors).to be_present
          expect(subject.errors.first.dig(:detail, :messages).first).to match(/Event could not be found:/)
          expect(subject.errors.first.dig(:detail, :row_index)).to eq(1)
        end
      end

      context "when a parent is not provided" do
        let(:options) { {} }

        it "returns untransformed proto records" do
          expect(proto_records.size).to eq(2)
        end

        it "adds a descriptive error" do
          expect(subject.errors.size).to eq(1)
          expect(subject.errors.first[:title]).to match(/Parent is missing/)
        end
      end
    end

    context "in an event group with a single event" do
      let(:event_group) { event_groups(:hardrock_2015) }
      let(:event) { event_group.events.first }

      context "when event name is provided" do
        let(:struct_1_event_name) { "Hardrock" }
        let(:struct_2_event_name) { "Hello" }

        it "imports the records without regard to the event name" do
          expect(proto_records.size).to eq(2)
          expect(proto_records).to all be_a(ProtoRecord)
        end

        it "returns rows with effort headers transformed to match the effort schema" do
          expect(first_proto_record.to_h.keys).to match_array(expected_schema)
        end

        it "assigns the expected events" do
          expect(proto_records.first[:event_id]).to eq(event.id)
          expect(proto_records.second[:event_id]).to eq(event.id)
        end

        it "assigns other attributes" do
          expect(first_proto_record[:first_name]).to eq(person_1.first_name)
          expect(first_proto_record[:last_name]).to eq(person_1.last_name)
          expect(first_proto_record[:gender]).to eq(person_1.gender)
          expect(first_proto_record[:state_code]).to eq("CO")
          expect(first_proto_record[:country_code]).to eq("US")
          expect(first_proto_record[:bib_number]).to eq(12)

          expect(second_proto_record[:first_name]).to eq(person_2.first_name)
          expect(second_proto_record[:last_name]).to eq(person_2.last_name)
          expect(second_proto_record[:gender]).to eq(person_2.gender)
          expect(second_proto_record[:state_code]).to eq("NY")
          expect(second_proto_record[:country_code]).to eq("US")
          expect(second_proto_record[:bib_number]).to eq(13)
        end

        it "deletes the event_name attribute" do
          expect(first_proto_record).not_to have_key(:event_name)
          expect(second_proto_record).not_to have_key(:event_name)
        end

        it "does not return errors" do
          expect(subject.errors).to be_empty
        end
      end

      context "when event name key is not provided" do
        let(:parsed_structs) do
          [
            OpenStruct.new(first: person_1.first_name, last: person_1.last_name, sex: person_1.gender, bib_number: 12, State: "Colorado", country: "US"),
            OpenStruct.new(first: person_2.first_name, last: person_2.last_name, sex: person_2.gender, bib_number: 13, state: "NY")
          ]
        end

        it "ignores the event names and imports the records" do
          expect(proto_records.size).to eq(2)
          expect(proto_records).to all be_a(ProtoRecord)
        end

        it "returns rows with effort headers transformed to match the effort schema" do
          expect(first_proto_record.to_h.keys).to match_array(expected_schema)
        end

        it "assigns the expected events" do
          expect(proto_records.first[:event_id]).to eq(event.id)
          expect(proto_records.second[:event_id]).to eq(event.id)
        end

        it "assigns other attributes" do
          expect(first_proto_record[:first_name]).to eq(person_1.first_name)
          expect(first_proto_record[:last_name]).to eq(person_1.last_name)
          expect(first_proto_record[:gender]).to eq(person_1.gender)
          expect(first_proto_record[:state_code]).to eq("CO")
          expect(first_proto_record[:country_code]).to eq("US")
          expect(first_proto_record[:bib_number]).to eq(12)

          expect(second_proto_record[:first_name]).to eq(person_2.first_name)
          expect(second_proto_record[:last_name]).to eq(person_2.last_name)
          expect(second_proto_record[:gender]).to eq(person_2.gender)
          expect(second_proto_record[:state_code]).to eq("NY")
          expect(second_proto_record[:country_code]).to eq("US")
          expect(second_proto_record[:bib_number]).to eq(13)
        end

        it "deletes the event_name attribute" do
          expect(first_proto_record).not_to have_key(:event_name)
          expect(second_proto_record).not_to have_key(:event_name)
        end

        it "does not return errors" do
          expect(subject.errors).to be_empty
        end
      end
    end
  end
end
