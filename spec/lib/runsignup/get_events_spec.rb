# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Runsignup::GetEvents do
  subject { described_class.new(race_id: race_id, user: user) }
  let(:race_id) { 85675 }
  let(:user) { users(:third_user) }
  let(:fake_credentials) { { "runsignup" => { "api_key" => "1234", "api_secret" => "2345" } } }

  describe "#perform" do
    let(:result) { subject.perform }

    context "when credentials are present" do
      before { allow(user).to receive(:credentials).and_return(fake_credentials) }

      context "when the race_id is valid" do
        let(:expected_result) do
          [
            ::Runsignup::Event.new(id: 661702, name: "24 hr", start_time: "2/10/2023 18:00", end_time: "2/11/2023 18:00"),
            ::Runsignup::Event.new(id: 661703, name: "12 hr", start_time: "2/11/2023 06:00", end_time: "2/11/2023 18:00"),
            ::Runsignup::Event.new(id: 661817, name: "6 hr", start_time: "2/10/2023 18:00", end_time: "2/11/2023 00:00"),
          ]
        end

        it "returns event structs" do
          VCR.use_cassette("runsignup/events") do
            expect(result).to eq(expected_result)
          end
        end
      end

      context "when the race id is not valid" do
        let(:race_id) { 9999999 }
        it "returns nil" do
          VCR.use_cassette("runsignup/events_invalid_race_id") do
            expect(result).to be_nil
          end
        end
      end
    end

    context "when credentials are not present" do
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end
end
