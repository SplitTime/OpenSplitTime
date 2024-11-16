# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProtoRecord, type: :model do
  it_behaves_like "transformable"

  describe "#[]" do
    let(:pr) { ProtoRecord.new(first_name: "Joe", age: 20, gender: "male") }
    let(:result) { pr[key] }
    context "when given nil" do
      let(:key) { nil }
      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when given a string for an existing key" do
      let(:key) { "first_name" }
      it "returns the value" do
        expect(result).to eq("Joe")
      end
    end

    context "when given a symbol for an existing key" do
      let(:key) { :first_name }
      it "returns the value" do
        expect(result).to eq("Joe")
      end
    end

    context "when given a string for a non-existing key" do
      let(:key) { "non_existing" }
      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when given a symbol for a non-existing key" do
      let(:key) { :non_existing }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#[]=" do
    it "may be used to add a key to an existing proto_record" do
      pr = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      pr[:id] = 1
      expect(pr[:id]).to eq(1)
    end
  end

  describe "==" do
    subject do
      ProtoRecord.new(
        record_type: "Effort",
        record_action: nil,
        first_name: "Joe",
        age: 21,
        gender: "male",
        children: subject_children,
      )
    end

    let(:other) do
      ProtoRecord.new(
        record_type: other_record_type,
        record_action: other_record_action,
        first_name: other_first_name,
        age: other_age,
        gender: other_gender,
        children: other_children,
      )
    end

    let(:subject_children) { [] }
    let(:other_record_type) { "Effort" }
    let(:other_record_action) { nil }
    let(:other_first_name) { "Joe" }
    let(:other_age) { 21 }
    let(:other_gender) { "male" }
    let(:other_children) { [] }

    let(:result) { subject == other }

    context "when record_type, record_action, attributes, and children match" do
      it { expect(result).to eq(true) }
    end

    context "when record_type is different" do
      let(:other_record_type) { "Person" }
      it { expect(result).to eq(false) }
    end

    context "when record_action is different" do
      let(:other_record_action) { "destroy" }
      it { expect(result).to eq(false) }
    end

    context "when any attribute is different" do
      let(:other_first_name) { "Jill" }
      it { expect(result).to eq(false) }
    end

    context "when children exist" do
      let(:subject_children) do
        [
          ProtoRecord.new(first_name: "Joe"),
          ProtoRecord.new(first_name: "Jill")
        ]
      end

      context "and all children are the same" do
        let(:other_children) do
          [
            ProtoRecord.new(first_name: "Joe"),
            ProtoRecord.new(first_name: "Jill")
          ]
        end

        it { expect(result).to eq(true) }
      end

      context "and any child is different" do
        let(:other_children) do
          [
            ProtoRecord.new(first_name: "Joe"),
            ProtoRecord.new(first_name: "Nancy")
          ]
        end

        it { expect(result).to eq(false) }
      end
    end
  end

  describe "#attributes" do
    it "may be set during initialization" do
      pr = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      attributes = pr.attributes
      expect(attributes).to eq(OpenStruct.new({ first_name: "Joe", age: 21, gender: "male" }))
    end

    it "responds to symbols or strings as keys indifferently" do
      pr = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      expect(pr[:first_name]).to eq("Joe")
      expect(pr["first_name"]).to eq("Joe")
    end

    it "sets attributes using symbols or strings indifferently" do
      pr = ProtoRecord.new
      pr[:first_name] = "Joe"
      expect(pr["first_name"]).to eq("Joe")
      pr["first_name"] = "Joe"
      expect(pr[:first_name]).to eq("Joe")
    end
  end

  describe "#children" do
    it "can be set at initialization with a single child record" do
      child = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      pr = ProtoRecord.new(first_name: "Fred", children: child)
      expect(pr.children).to eq([child])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({ first_name: "Fred" })
    end

    it "can be set at initialization with an array of child records" do
      child1 = ProtoRecord.new(first_name: "Joe")
      child2 = ProtoRecord.new(first_name: "Jill")
      pr = ProtoRecord.new(age: 99, children: [child1, child2])
      expect(pr.children).to eq([child1, child2])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({ age: 99 })
    end

    it "can be added to using the << operator" do
      child = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      pr = ProtoRecord.new(favorite_color: "Red")
      pr.children << child
      expect(pr.children).to eq([child])
      expect(pr.attributes).not_to respond_to(:children)
      expect(pr.to_h).to eq({ favorite_color: "Red" })
    end
  end

  describe "#deep_dup" do
    let(:subject) do
      ProtoRecord.new(
        record_type: "Person",
        record_action: "destroy",
        first_name: "Joe",
        age: 20,
        gender: "male",
        tags: ["blue", "green"],
      )
    end

    let(:result) { subject.deep_dup }

    it "returns a ProtoRecord object" do
      expect(result).to be_a(ProtoRecord)
    end

    it "duplicates record_type and record_action correctly" do
      expect(result.record_type).to eq(:Person)
      expect(result.record_action).to eq(:destroy)
    end

    it "duplicates all attributes correctly" do
      result.attributes.to_h.each do |key, value|
        expect(value).to eq(subject[key])
      end
    end

    it "creates a new OpenStruct for the attributes" do
      expect(result.attributes.object_id).not_to eq(subject.attributes.object_id)
    end

    it "creates new object ids for non-numeric values" do
      result.attributes.to_h.each do |key, _|
        next if result[key].is_a?(Numeric)

        expect(result[key].object_id).not_to eq(subject[key].object_id)
      end
    end

    context "when children are present" do
      subject do
        ProtoRecord.new(
          record_type: "Effort",
          children: [
            ProtoRecord.new(
              record_type: "SplitTime",
              absolute_time: "2024-04-01 06:00:00"
            ),
            ProtoRecord.new(
              record_type: "SplitTime",
              absolute_time: "2024-04-01 06:30:00"
            ),
          ]
        )
      end

      it "duplicates children correctly" do
        expect(result.children).to eq(subject.children)
      end
    end
  end

  describe "#record_class" do
    it "returns the class of the record_type" do
      pr = ProtoRecord.new(record_type: :effort)
      expect(pr.record_class).to eq(Effort)
    end

    it "returns nil when record_type is nil" do
      pr = ProtoRecord.new
      expect(pr.record_class).to be_nil
    end
  end

  describe "#params_class" do
    it "returns the class of the record_type" do
      pr = ProtoRecord.new(record_type: :effort)
      expect(pr.params_class).to eq(EffortParameters)
    end

    it "returns nil when record_type is nil" do
      pr = ProtoRecord.new
      expect(pr.params_class).to be_nil
    end
  end

  describe "#to_h" do
    it "returns a hash of the attributes" do
      pr = ProtoRecord.new(first_name: "Joe", age: 21, gender: "male")
      hash = pr.to_h
      expect(hash).to eq({ first_name: "Joe", age: 21, gender: "male" })
    end
  end

  describe "#transform_as" do
    let(:pr) { ProtoRecord.new(attributes) }
    before { pr.transform_as(model, options) }

    context "for an effort" do
      let(:model) { :effort }
      let(:attributes) { { sex: gender, country: "United States", state: "California", birthdate: "09/01/66" }.merge(start_time_attributes).merge(start_offset_attributes) }
      let(:gender) { "M" }
      let(:start_time_attributes) { {} }
      let(:start_offset_attributes) { {} }
      let(:options) { { event: event } }
      let(:event) { Event.new(id: 1, event_group: event_group, scheduled_start_time_local: start_time) }
      let(:event_group) { EventGroup.new(home_time_zone: "Pacific Time (US & Canada)") }
      let(:start_time) { "2018-06-30 08:00:00" }

      it "sets the record type and normalizes data" do
        expect(pr.record_type).to eq(:effort)
        expect(pr.to_h).to eq({ gender: "male", country_code: "US", state_code: "CA", birthdate: "1966-09-01", event_id: event.id, scheduled_start_time: event.scheduled_start_time })
      end

      context "for a runner listed as non-binary" do
        let(:gender) { "N" }

        it "sets the record type and normalizes data" do
          expect(pr.record_type).to eq(:effort)
          expect(pr.to_h).to eq({ gender: "nonbinary", country_code: "US", state_code: "CA", birthdate: "1966-09-01", event_id: event.id, scheduled_start_time: event.scheduled_start_time })
        end
      end

      context "when scheduled start time is not provided" do
        context "and start offset is not provided" do
          it "sets scheduled start time to that of the event" do
            expect(pr[:scheduled_start_time]).to eq(event.scheduled_start_time)
          end
        end

        context "and start offset is provided" do
          let(:start_offset_attributes) { { start_offset: "0:30:00" } }
          it "sets scheduled start time using the start offset" do
            expect(pr[:scheduled_start_time]).to eq(event.scheduled_start_time + 30.minutes)
          end
        end
      end

      context "when scheduled start time is provided as a standard datetime" do
        let(:start_time_attributes) { { scheduled_start_time_local: "2018-06-30 09:00:00" } }
        context "and start offset is not provided" do
          it "uses the scheduled start time" do
            expect(pr[:scheduled_start_time]).to eq(event.scheduled_start_time + 1.hour)
          end
        end

        context "and start offset is provided" do
          let(:start_offset_attributes) { { start_offset: "0:30:00" } }
          it "ignores the start offset and uses the scheduled start time" do
            expect(pr[:scheduled_start_time]).to eq(event.scheduled_start_time + 1.hour)
          end
        end
      end

      context "when scheduled start time is provided as a time only" do
        let(:start_time_attributes) { { scheduled_start_time_local: "09:00:00" } }
        it "infers the event date" do
          expect(pr[:scheduled_start_time]).to eq(event.scheduled_start_time + 1.hour)
        end
      end
    end

    context "for a split" do
      let(:model) { :split }
      let(:attributes) { { distance: distance, kind: kind } }
      let(:baseline_split) { Split.new(distance: distance) }
      let(:distance) { 10.5 } # miles
      let(:kind) { "Int" }
      let(:options) { { event: event } }
      let(:event) { Event.new }

      it "sets the record type and normalizes data" do
        expect(pr.record_type).to eq(:split)
        expect(pr.to_h[:distance_from_start]).to eq(baseline_split.distance_from_start)
        expect(pr.to_h[:kind]).to eq("intermediate")
      end
    end
  end
end
