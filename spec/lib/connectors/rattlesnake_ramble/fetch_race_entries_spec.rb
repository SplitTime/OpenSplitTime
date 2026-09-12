require "rails_helper"

RSpec.describe ::Connectors::RattlesnakeRamble::FetchRaceEntries do
  subject { described_class.new(race_edition_id: 1, user: user) }

  include_context "user_with_credentials"

  describe "#perform" do
    let(:result) { subject.perform }

    it "returns race entries with racer attributes mapped from the raw response" do
      VCR.use_cassette("rattlesnake_ramble/get_race_edition/valid") do
        expect(result.size).to eq(2)
        expect(result).to all(be_a(::Connectors::RattlesnakeRamble::Models::RaceEntry))

        race_entry = result.first
        expect(race_entry.bib_number).to eq(3)
        expect(race_entry.first_name).to eq("Bubba")
        expect(race_entry.last_name).to eq("Gump")
        expect(race_entry.gender).to eq("male")
        expect(race_entry.birthdate).to eq("1971-04-24")
        expect(race_entry.email).to eq("bubba@gump.com")
        expect(race_entry.city).to eq("Atlanta")
        expect(race_entry.state_code).to eq("GA")
      end
    end
  end
end
