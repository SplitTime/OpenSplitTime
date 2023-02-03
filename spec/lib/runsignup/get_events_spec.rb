# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Runsignup::GetEvents do
  subject { described_class.new(race_id: race_id, user: user) }
  let(:race_id) { 123 }
  let(:user) { users(:third_user) }
  let(:fake_credentials) { { runsignup: { api_key: "api-123", api_secret: "api-secret-123" } } }

  describe "#perform" do
    let(:result) { subject.perform }
    context "when credentials are present" do
      before do
        user.update(credentials: fake_credentials)
        allow(subject).to receive(:parsed_body).and_return(parsed_body)
      end


      context "when the race_id is valid" do
        let(:parsed_body) do
          { "race" =>
              { "race_id" => 81625,
                "name" => "Running Up for Air - Grandeur",
                "last_date" => "02/04/2022",
                "last_end_date" => "02/05/2022",
                "next_date" => "02/03/2023",
                "next_end_date" => "02/04/2023",
                "timezone" => "America/Denver",
                "events" =>
                  [
                    { "event_id" => 661804, "name" => "24 hr", "start_time" => "2/3/2023 18:00", "end_time" => "2/4/2023 18:00" },
                    { "event_id" => 661805, "name" => "12 hr", "start_time" => "2/4/2023 06:00", "end_time" => "2/4/2023 18:00" },
                  ]
              }
          }
        end

        let(:expected_result) do
          [
            ::Runsignup::Event.new(id: 661804, name: "24 hr", start_time: "2/3/2023 18:00", end_time: "2/4/2023 18:00"),
            ::Runsignup::Event.new(id: 661805, name: "12 hr", start_time: "2/4/2023 06:00", end_time: "2/4/2023 18:00"),
          ]
        end

        it "returns event structs" do
          expect(result).to match_array(expected_result)
        end
      end

      context "when the race id is not valid" do
        let(:parsed_body) do
          { "error" => { "error_code" => 201, "error_msg" => "Race not found." } }
        end

        it "returns nil" do
          expect(result).to be_nil
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
