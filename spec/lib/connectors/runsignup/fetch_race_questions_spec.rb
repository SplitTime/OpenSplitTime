require "rails_helper"

RSpec.describe ::Connectors::Runsignup::FetchRaceQuestions do
  subject(:result) { described_class.perform(race_id: race_id, event_id: event_id, user: user, client: client) }

  let(:race_id) { 174_571 }
  let(:client) { instance_double(::Connectors::Runsignup::Client) }
  let(:event_id) { 1_080_834 }

  include_context "user_with_credentials"

  before do
    Rails.cache.clear
    allow(client).to receive(:get_participants).with(race_id, event_id, 1).and_return(response_body)
  end

  context "with a typical multi-question response" do
    let(:response_body) do
      {
        participants: [
          {
            user: { first_name: "A", last_name: "B" },
            question_responses: [
              { question_id: 100, question_text: "Emergency Contact Name", response: "X" },
              { question_id: 200, question_text: "Bib Name", response: "Y" },
            ],
          },
          {
            user: { first_name: "C", last_name: "D" },
            question_responses: [
              { question_id: 200, question_text: "Bib Name", response: "Z" },
              { question_id: 300, question_text: "Fun Fact", response: "Q" },
            ],
          },
        ],
      }.to_json
    end

    it "returns the union of distinct (question_id, question_text) tuples" do
      expect(result.map(&:id)).to eq([100, 200, 300])
      expect(result.map(&:text)).to eq(["Emergency Contact Name", "Bib Name", "Fun Fact"])
    end

    it "returns an array of Question structs" do
      expect(result.first).to be_a(::Connectors::Runsignup::Models::Question)
    end
  end

  context "when no participants exist" do
    let(:response_body) { { participants: [] }.to_json }

    it "returns an empty array" do
      expect(result).to eq([])
    end
  end

  context "when participants have no question_responses key" do
    let(:response_body) do
      { participants: [{ user: { first_name: "A", last_name: "B" } }] }.to_json
    end

    it "returns an empty array without raising" do
      expect(result).to eq([])
    end
  end

  context "when the response is wrapped in an outer array (the API sometimes returns this shape)" do
    let(:response_body) do
      [{
        event: { event_id: event_id, participants: [] },
        participants: [
          { user: { first_name: "A" }, question_responses: [{ question_id: 99, question_text: "Q" }] },
        ],
      }].to_json
    end

    it "unwraps and processes the first element" do
      expect(result.map(&:id)).to eq([99])
    end
  end

  context "when called twice with the same race_id and event_id" do
    let(:response_body) do
      {
        participants: [{
          user: { first_name: "A" },
          question_responses: [{ question_id: 1, question_text: "X" }],
        }],
      }.to_json
    end

    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    it "caches the result and only hits the client once" do
      described_class.perform(race_id: race_id, event_id: event_id, user: user, client: client)
      described_class.perform(race_id: race_id, event_id: event_id, user: user, client: client)
      expect(client).to have_received(:get_participants).once
    end
  end

  context "when text has trailing whitespace" do
    let(:response_body) do
      {
        participants: [{
          user: { first_name: "A" },
          question_responses: [{ question_id: 1, question_text: "  Padded text  " }],
        }],
      }.to_json
    end

    it "strips the question_text" do
      expect(result.first.text).to eq("Padded text")
    end
  end
end
