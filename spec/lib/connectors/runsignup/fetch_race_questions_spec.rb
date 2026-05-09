require "rails_helper"

RSpec.describe ::Connectors::Runsignup::FetchRaceQuestions do
  subject(:result) { described_class.perform(race_id: race_id, user: user, client: client) }

  let(:race_id) { 174_571 }
  let(:client) { instance_double(::Connectors::Runsignup::Client) }

  include_context "user_with_credentials"

  before do
    Rails.cache.clear
    allow(client).to receive(:get_race).with(race_id, include_questions: true).and_return(response_body)
  end

  context "with a typical multi-question race" do
    let(:response_body) do
      {
        race: {
          race_id: race_id,
          name: "R",
          questions: [
            { question_id: 100, question_text: "Emergency Contact Name", question_type_code: "T" },
            { question_id: 200, question_text: "Bib Name", question_type_code: "T" },
            { question_id: 300, question_text: "Fun Fact", question_type_code: "T" },
          ],
        },
      }.to_json
    end

    it "returns the question definitions directly" do
      expect(result.map(&:id)).to eq([100, 200, 300])
      expect(result.map(&:text)).to eq(["Emergency Contact Name", "Bib Name", "Fun Fact"])
    end

    it "returns an array of Question structs" do
      expect(result.first).to be_a(::Connectors::Runsignup::Models::Question)
    end
  end

  context "when the race has no configured questions" do
    let(:response_body) do
      { race: { race_id: race_id, name: "R", questions: [] } }.to_json
    end

    it "returns an empty array" do
      expect(result).to eq([])
    end
  end

  context "when the race response has no questions key" do
    let(:response_body) do
      { race: { race_id: race_id, name: "R" } }.to_json
    end

    it "returns an empty array without raising" do
      expect(result).to eq([])
    end
  end

  context "when the response is wrapped in an outer array (the API sometimes returns this shape)" do
    let(:response_body) do
      [{ race: { race_id: race_id, questions: [{ question_id: 99, question_text: "Q" }] } }].to_json
    end

    it "unwraps and processes the first element" do
      expect(result.map(&:id)).to eq([99])
    end
  end

  context "when called twice with the same race_id" do
    let(:response_body) do
      { race: { race_id: race_id, questions: [{ question_id: 1, question_text: "X" }] } }.to_json
    end

    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    it "caches the result and only hits the client once" do
      described_class.perform(race_id: race_id, user: user, client: client)
      described_class.perform(race_id: race_id, user: user, client: client)
      expect(client).to have_received(:get_race).once
    end
  end

  context "when text has trailing whitespace" do
    let(:response_body) do
      { race: { race_id: race_id, questions: [{ question_id: 1, question_text: "  Padded text  " }] } }.to_json
    end

    it "strips the question_text" do
      expect(result.first.text).to eq("Padded text")
    end
  end
end
