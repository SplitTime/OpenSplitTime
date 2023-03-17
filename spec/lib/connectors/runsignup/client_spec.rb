# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Connectors::Runsignup::Client do
  subject { described_class.new(user) }

  include_context "user_with_runsignup_credentials"

  describe "initialize" do
    context "when runsignup credentials are present" do
      it { expect { subject }.not_to raise_error }
    end

    context "when runsignup credentials are not present" do
      include_context "user_without_credentials"

      it { expect { subject }.to raise_error Connectors::Errors::MissingCredentials }
    end
  end

  describe "#get_race" do
    let(:result) { subject.get_race(race_id) }
    let(:race_id) { 85675 }

    context "when the race is found" do
      it "returns a json blob with race and event information" do
        VCR.use_cassette("runsignup/get_race/valid") do
          parsed_result = JSON.parse(result)

          race = parsed_result["race"]
          expect(race).to be_present
          expect(race.dig("race_id")).to eq(race_id)
          expect(race.dig("name")).to eq("Running Up For Air")

          events = parsed_result.dig("race", "events")
          expect(events).to be_present
          expect(events.count).to eq(3)

          event = events.first
          expect(event.dig("event_id")).to eq(661702)
          expect(event.dig("name")).to eq("24 hr")
        end
      end
    end

    context "when the race is not found" do
      let(:race_id) { 9999999 }
      it "raises an error" do
        VCR.use_cassette("runsignup/get_race/not_found") do
          expect { result }.to raise_error Connectors::Errors::NotFound
        end
      end
    end
  end

  describe "#get_participants" do
    let(:result) { subject.get_participants(race_id, event_id, page) }
    let(:race_id) { 85675 }
    let(:event_id) { 661702 }
    let(:page) { 1 }

    context "when credentials are valid" do
      let(:test_credentials) { { "runsignup" => { "api_key" => "1234", "api_secret" => "2345" } } }

      context "when the race and event are found" do
        it "returns a json blob with race and event information" do
          VCR.use_cassette("runsignup/get_participants/valid") do
            parsed_result = JSON.parse(result)

            event = parsed_result.first["event"]
            expect(event).to be_present
            expect(event["event_id"]).to eq(event_id)

            participants = parsed_result.first["participants"]
            expect(participants).to be_present
            expect(participants.size).to eq(2)

            participant = participants.first
            expect(participant.dig("bib_num")).to eq(3)
            expect(participant.dig("user", "first_name")).to eq("Bubba")
            expect(participant.dig("user", "last_name")).to eq("Gump")
          end
        end
      end

      context "when the race is not found" do
        let(:race_id) { 9999999 }
        it "raises an error" do
          VCR.use_cassette("runsignup/get_participants/race_not_found") do
            expect { result }.to raise_error Connectors::Errors::NotFound
          end
        end
      end

      context "when the event is not found" do
        let(:event_id) { 9999999 }
        it "raises an error" do
          VCR.use_cassette("runsignup/get_participants/event_not_found") do
            expect { result }.to raise_error Connectors::Errors::NotFound
          end
        end
      end
    end

    context "when credentials are invalid" do
      it "raises NotAuthorized" do
        VCR.use_cassette("runsignup/get_participants/not_authorized") do
          expect { result }.to raise_error(Connectors::Errors::NotAuthorized)
        end
      end
    end
  end
end
