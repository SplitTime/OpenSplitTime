require "rails_helper"

RSpec.describe FontAwesome6::Parsers::IconParser do
  subject { described_class.new(icon_name, options) }

  let(:icon_name) { "user" }
  let(:options) { {} }

  describe "#render" do
    let(:result) { subject.render }

    context "when the icon has no text" do
      it { expect(result).to eq("<i class=\"fas fa-user\"></i>") }

      context "when regular type is specified" do
        let(:options) { { type: :regular } }

        it { expect(result).to eq("<i class=\"far fa-user\"></i>") }
      end

      context "when brand type is specified" do
        let(:options) { { type: :brand } }

        it { expect(result).to eq("<i class=\"fab fa-user\"></i>") }
      end
    end

    context "when the icon has text" do
      let(:options) { { text: "Hello" } }

      it { expect(result).to eq("<i class=\"fas fa-user\"></i><span class=\"fa6-text\">Hello</span>") }

      context "when regular type is specified" do
        let(:options) { { type: :regular, text: "Hello" } }

        it { expect(result).to eq("<i class=\"far fa-user\"></i><span class=\"fa6-text\">Hello</span>") }
      end

      context "when brand type is specified" do
        let(:options) { { type: :brand, text: "Hello" } }

        it { expect(result).to eq("<i class=\"fab fa-user\"></i><span class=\"fa6-text\">Hello</span>") }
      end
    end

    context "when the icon has text on the right" do
      let(:options) { { text: "Hello", right: true } }

      it { expect(result).to eq("<span class=\"fa6-text-r\">Hello</span><i class=\"fas fa-user\"></i>") }

      context "when regular type is specified" do
        let(:options) { { type: :regular, text: "Hello", right: true } }

        it { expect(result).to eq("<span class=\"fa6-text-r\">Hello</span><i class=\"far fa-user\"></i>") }
      end

      context "when brand type is specified" do
        let(:options) { { type: :brand, text: "Hello", right: true } }

        it { expect(result).to eq("<span class=\"fa6-text-r\">Hello</span><i class=\"fab fa-user\"></i>") }
      end
    end

    context "when the icon has a size" do
      let(:options) { { size: "2x" } }

      it { expect(result).to eq("<i class=\"fas fa-user fa-2x\"></i>") }

      context "when regular type is specified" do
        let(:options) { { type: :regular, size: "2x" } }

        it { expect(result).to eq("<i class=\"far fa-user fa-2x\"></i>") }
      end

      context "when brand type is specified" do
        let(:options) { { type: :brand, size: "2x" } }

        it { expect(result).to eq("<i class=\"fab fa-user fa-2x\"></i>") }
      end
    end
  end
end
