# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Connectors::RattlesnakeRamble::Client do
  subject { described_class.new(user) }

  include_context "user_with_credentials"

  describe "initialize" do
    context "when credentials are present" do
      it { expect { subject }.not_to raise_error }
    end

    context "when credentials are not present" do
      include_context "user_without_credentials"

      it { expect { subject }.to raise_error Connectors::Errors::MissingCredentials }
    end
  end

  describe "#get_race_editions" do
    let(:result) { subject.get_race_editions }

    context "when credentials are valid" do
      it "returns a json blob with an array of race editions" do
        VCR.use_cassette("rattlesnake_ramble/get_race_editions/authorized") do
          race_editions = JSON.parse(result)
          expect(race_editions).to be_a(Array)

          race_edition = race_editions.first
          expect(race_edition.dig("id")).to eq(1)
          expect(race_edition.dig("race_name")).to eq("Rattlesnake Ramble Trail Race - Odd Years")
        end
      end
    end

    context "when credentials are invalid" do
      it "returns an error and unauthorized status" do
        VCR.use_cassette("rattlesnake_ramble/get_race_editions/not_authorized") do
          expect { result }.to raise_error(Connectors::Errors::NotAuthenticated)
        end
      end
    end
  end

  describe "#get_race_edition" do
    let(:result) { subject.get_race_edition(race_edition_id) }
    let(:race_edition_id) { 1 }

    context "when credentials are valid" do
      context "when the race_edition is found" do
        it "returns a json blob with race edition and race entries information" do
          VCR.use_cassette("rattlesnake_ramble/get_race_edition/valid") do
            parsed_result = JSON.parse(result)

            expect(parsed_result["date"]).to eq("2023-09-16")
            expect(parsed_result.dig("race", "name")).to eq("Rattlesnake Ramble Trail Race - Odd Years")

            race_entries = parsed_result["race_entries"]
            expect(race_entries).to be_present
            expect(race_entries.size).to eq(2)

            entry = race_entries.first
            expect(entry.dig("bib_number")).to eq(3)
            expect(entry.dig("racer", "first_name")).to eq("Bubba")
            expect(entry.dig("racer", "last_name")).to eq("Gump")
          end
        end
      end

      context "when the race is not found" do
        let(:race_edition_id) { 9999999 }
        it "raises an error" do
          VCR.use_cassette("rattlesnake_ramble/get_race_edition/not_found") do
            expect { result }.to raise_error Connectors::Errors::NotFound
          end
        end
      end
    end

    context "when credentials are invalid" do
      it "raises NotAuthorized" do
        VCR.use_cassette("rattlesnake_ramble/get_race_edition/not_authorized") do
          expect { result }.to raise_error(Connectors::Errors::NotAuthenticated)
        end
      end
    end
  end
end
