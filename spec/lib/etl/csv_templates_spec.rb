require "rails_helper"

RSpec.describe Etl::CsvTemplates do
  subject { described_class.new(format, parent) }

  let(:format) { :event_course_splits }
  let(:parent) { courses(:sum_55k_course) }

  describe "#headers" do
    let(:result) { subject.headers }

    context "when there is no variable component" do
      let(:expected) do
        [
          "Split Name",
          "Distance From Start",
          "Kind",
          "Vert Gain From Start",
          "Vert Loss From Start",
          "Latitude",
          "Longitude",
          "Elevation",
          "Sub Split Kinds",
        ]
      end

      it "returns the fixed headers" do
        expect(result).to eq(expected)
      end
    end

    context "when there is a variable component" do
      let(:format) { :event_entrants_with_military_times }
      let(:parent) { events(:sum_55k) }

      let(:expected) do
        [
          "First Name",
          "Last Name",
          "Gender",
          "Birthdate",
          "Age",
          "Email",
          "Phone",
          "City",
          "State",
          "Country",
          "Bib Number",
          "Start",
          "Molas Pass (Aid1) In",
          "Molas Pass (Aid1) Out",
          "Rolling Pass (Aid2) In",
          "Rolling Pass (Aid2) Out",
          "Bandera Mine (Aid5) In",
          "Bandera Mine (Aid5) Out",
          "Anvil CG (Aid6) In",
          "Anvil CG (Aid6) Out",
          "Finish",
        ]
      end

      it "returns the fixed headers plus the variable headers using parent info" do
        expect(result).to eq(expected)
      end
    end

    context "for event_group_entrants" do
      let(:format) { :event_group_entrants }
      let(:parent) { event_groups(:hardrock_2015) }

      context "when the event_group has only one event" do
        let(:expected) do
          [
            "First Name",
            "Last Name",
            "Gender",
            "Birthdate",
            "Age",
            "Email",
            "Phone",
            "City",
            "State",
            "Country",
            "Bib Number",
          ]
        end

        it "returns the effort headers" do
          expect(result).to eq(expected)
        end
      end

      context "when the event group has multiple events" do
        let(:parent) { event_groups(:sum) }
        let(:expected) do
          [
            "First Name",
            "Last Name",
            "Gender",
            "Birthdate",
            "Age",
            "Email",
            "Phone",
            "City",
            "State",
            "Country",
            "Bib Number",
            "Event Name",
          ]
        end

        it "returns the effort headers plus Event Name" do
          expect(result).to eq(expected)
        end
      end
    end
  end
end
