require "rails_helper"

RSpec.describe DataStatusHelper do
  describe "#text_with_status_indicator" do
    context "when status is nil" do
      it "returns the time without any indicator" do
        result = helper.text_with_status_indicator("12:45:30 PM", nil)
        expect(result).to eq("12:45:30 PM")
      end
    end

    context "when status is good" do
      it "returns the time without any indicator" do
        result = helper.text_with_status_indicator("12:45:30 PM", :good)
        expect(result).to eq("12:45:30 PM")
      end
    end

    context "when status is bad" do
      it "returns an icon with the time wrapped in a nowrap span" do
        result = helper.text_with_status_indicator("12:45:30 PM", :bad)
        expect(result).to have_css("span.text-nowrap")
        expect(result).to have_css("i.fa-circle-xmark.text-danger")
        expect(result).to have_css("span.fa6-text", text: "12:45:30 PM")
      end

      it "includes tooltip data attributes" do
        result = helper.text_with_status_indicator("12:45:30 PM", :bad)
        expect(result).to have_css("i[data-controller='tooltip'][data-bs-original-title='Time Appears Bad']")
      end
    end

    context "when status is questionable" do
      it "returns an icon with the time wrapped in a nowrap span" do
        result = helper.text_with_status_indicator("12:45:30 PM", :questionable)
        expect(result).to have_css("span.text-nowrap")
        expect(result).to have_css("i.fa-circle-question.text-warning")
        expect(result).to have_css("span.fa6-text", text: "12:45:30 PM")
      end

      it "includes tooltip data attributes" do
        result = helper.text_with_status_indicator("12:45:30 PM", :questionable)
        expect(result).to have_css("i[data-controller='tooltip'][data-bs-original-title='Time Appears Questionable']")
      end
    end

    context "when data_type option is provided" do
      it "uses the custom data type in the tooltip" do
        result = helper.text_with_status_indicator("5.2", :bad, data_type: :pace)
        expect(result).to have_css("i[data-bs-original-title='Pace Appears Bad']")
      end
    end
  end
end
