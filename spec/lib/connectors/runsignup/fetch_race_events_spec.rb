require "rails_helper"

RSpec.describe ::Connectors::Runsignup::FetchRaceEvents do
  subject { described_class.new(race_id: race_id, user: user) }
  let(:race_id) { 85675 }

  include_context "user_with_credentials"

  describe "#perform" do
    let(:result) { subject.perform }
    let(:client) { ::Connectors::Runsignup::Client.new(user) }

    before { allow(::Connectors::Runsignup::Client).to receive(:new).with(user).and_return(client) }

    context "when the race_id is valid" do
      before { allow(client).to receive(:get_race).with(race_id).and_return(response_body) }

      let(:response_body) do
        '{
      "race":{
        "race_id":85675,
        "name":"Running Up For Air",
        "last_date":"02\/25\/2022",
        "last_end_date":"02\/26\/2022",
        "next_date":"02\/10\/2023",
        "next_end_date":"02\/11\/2023",
        "is_draft_race":"F",
        "is_private_race":"F",
        "is_registration_open":"T",
        "created":"1\/20\/2020 16:55",
        "last_modified":"2\/8\/2023 21:39",
        "description":"<p>A Race<\/p>",
        "events":[
          {
            "event_id":661702,
            "race_event_days_id":243601,
            "name":"24 hr",
            "details":null,
            "start_time":"2\/10\/2023 18:00",
            "end_time":"2\/11\/2023 18:00"
          },
          {
            "event_id":661703,
            "race_event_days_id":243601,
            "name":"12 hr",
            "details":null,
            "start_time":"2\/11\/2023 06:00",
            "end_time":"2\/11\/2023 18:00"
          },
          {
            "event_id":661817,
            "race_event_days_id":243601,
            "name":"6 hr",
            "details":null,
            "start_time":"2\/10\/2023 18:00",
            "end_time":"2\/11\/2023 00:00"
          }
        ]}}'
      end

      let(:expected_result) do
        [
          ::Connectors::Runsignup::Models::Event.new(id: 661702, name: "24 hr", start_time: "2/10/2023 18:00", end_time: "2/11/2023 18:00"),
          ::Connectors::Runsignup::Models::Event.new(id: 661703, name: "12 hr", start_time: "2/11/2023 06:00", end_time: "2/11/2023 18:00"),
          ::Connectors::Runsignup::Models::Event.new(id: 661817, name: "6 hr", start_time: "2/10/2023 18:00", end_time: "2/11/2023 00:00"),
        ]
      end

      it "returns event structs" do
        expect(result).to eq(expected_result)
      end
    end

    context "when the race id is not valid" do
      before { allow(client).to receive(:get_race).with(race_id).and_raise ::Connectors::Errors::NotFound }

      it { expect { result }.to raise_error ::Connectors::Errors::NotFound }
    end
  end
end
