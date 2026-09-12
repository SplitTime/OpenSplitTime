require "rails_helper"

RSpec.describe ::Connectors::RattlesnakeRamble::FetchRaceEditions do
  subject { described_class.new(user: user) }

  include_context "user_with_credentials"

  describe "#perform" do
    let(:result) { subject.perform }

    it "returns race editions with attributes mapped from the raw response" do
      VCR.use_cassette("rattlesnake_ramble/get_race_editions/authorized") do
        expect(result).to all(be_a(::Connectors::RattlesnakeRamble::Models::RaceEdition))

        race_edition = result.first
        expect(race_edition.id).to eq(1)
        expect(race_edition.date).to eq("2017-09-09")
        expect(race_edition.name).to eq("Rattlesnake Ramble Trail Race - Odd Years")
        expect(race_edition.start_time).to eq("2017-09-09".in_time_zone("UTC"))
      end
    end
  end
end
