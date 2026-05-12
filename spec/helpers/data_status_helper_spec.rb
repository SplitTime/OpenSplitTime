require "rails_helper"

RSpec.describe DataStatusHelper do
  describe "#text_with_status_indicator" do
    let(:result) { helper.text_with_status_indicator(text, status, options) }
    let(:text) { "12:45:30 PM" }
    let(:status) { nil }
    let(:options) { {} }

    context "when status is nil" do
      it "returns the time without any indicator" do
        expect(result).to eq("12:45:30 PM")
      end
    end

    context "when status is good" do
      let(:status) { :good }

      it "returns the time without any indicator" do
        expect(result).to eq("12:45:30 PM")
      end
    end

    context "when status is bad" do
      let(:status) { :bad }

      it "returns an icon with the time wrapped in a nowrap span" do
        expect(result).to have_css("span.text-nowrap")
        expect(result).to have_css("i.fa-circle-xmark.text-danger")
        expect(result).to have_css("span.fa6-text", text: "12:45:30 PM")
      end

      it "includes tooltip data attributes" do
        expect(result).to have_css("i[data-controller='tooltip'][data-bs-original-title='Time Appears Bad']")
      end
    end

    context "when status is questionable" do
      let(:status) { :questionable }

      it "returns an icon with the time wrapped in a nowrap span" do
        expect(result).to have_css("span.text-nowrap")
        expect(result).to have_css("i.fa-circle-question.text-warning")
        expect(result).to have_css("span.fa6-text", text: "12:45:30 PM")
      end

      it "includes tooltip data attributes" do
        expect(result).to have_css("i[data-controller='tooltip'][data-bs-original-title='Time Appears Questionable']")
      end
    end

    context "when data_type option is provided" do
      let(:text) { "5.2" }
      let(:status) { :bad }
      let(:options) { { data_type: :pace } }

      it "uses the custom data type in the tooltip" do
        expect(result).to have_css("i[data-bs-original-title='Pace Appears Bad']")
      end
    end

    context "when a reason option is provided" do
      let(:status) { :questionable }
      let(:options) { { reason: "segment time too slow" } }

      it "appends the reason to the tooltip" do
        expect(result).to have_css("i[data-bs-original-title='Time Appears Questionable: Segment Time Too Slow']")
      end
    end

    context "when the reason option is blank" do
      let(:status) { :bad }
      let(:options) { { reason: "" } }

      it "renders the tooltip without a trailing colon" do
        expect(result).to have_css("i[data-bs-original-title='Time Appears Bad']")
      end
    end
  end
end
