require "rails_helper"

RSpec.describe SourceTextable do
  subject { dummy_class.new(source, created_by).source_text }

  let(:dummy_class) { Struct.new(:source, :created_by) { include SourceTextable } }
  let(:created_by) { nil }

  context "when source starts with ost-remote-2" do
    let(:source) { "ost-remote-2-abcd" }

    it { is_expected.to eq("OSTR2 (abcd)") }
  end

  context "when source starts with ost-remote" do
    let(:source) { "ost-remote-abcd" }

    it { is_expected.to eq("OSTR (abcd)") }
  end

  context "when source starts with ost-live-entry" do
    let(:source) { "ost-live-entry" }
    let(:created_by) { "user@example.com" }

    it { is_expected.to eq("Live Entry (user@example.com)") }
  end

  context "when source is raceresult-webhook" do
    let(:source) { "raceresult-webhook" }

    it { is_expected.to eq("RRWEB") }
  end

  context "when source starts with raceresult-webhook-" do
    let(:source) { "raceresult-webhook-abc1" }

    it { is_expected.to eq("RRWEB (abc1)") }
  end

  context "when source is anything else" do
    let(:source) { "some-other-source" }

    it { is_expected.to eq("some-other-source") }
  end
end
