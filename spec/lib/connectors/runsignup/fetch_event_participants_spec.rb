# frozen_string_literal: true

require "rails_helper"

RSpec.describe ::Connectors::Runsignup::FetchEventParticipants do
  subject { described_class.new(race_id: race_id, event_id: event_id, user: user) }

  let(:race_id) { 85675 }
  let(:event_id) { 661702 }

  include_context "user_with_credentials"

  describe "#perform" do
    let(:result) { subject.perform }
    let(:client) { ::Connectors::Runsignup::Client.new(user) }

    before { allow(::Connectors::Runsignup::Client).to receive(:new).with(user).and_return(client) }

    context "when the race_id is valid" do
      before do
        allow(client).to receive(:get_race).with(race_id).and_return(race_response_body)
        allow(client).to receive(:get_participants).with(race_id, event_id, 1).and_return(participants_response_body_page_1)
        allow(client).to receive(:get_participants).with(race_id, event_id, 2).and_return(participants_response_body_page_2)
        allow(client).to receive(:get_participants).with(race_id, event_id, 3).and_return(participants_response_body_page_3)
      end

      let(:race_response_body) do
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

      let(:participants_response_body_page_1) do
        '[{
        "event":{"event_id":661702,"participants":[]},
        "participants":[
          {
            "user":{
              "user_id":18423667,
              "first_name":"Bubba",
              "middle_name":null,
              "last_name":"Gump",
              "email":"bubba@msn.com",
              "address":{"street":"123 Main Street","city":"Atlanta","state":"GA","zipcode":"34343","country_code":"US"},
              "dob":"1958-01-01",
              "gender":"M",
              "phone":"404-583-3514"
              },
            "event_id":661702,
            "bib_num":3,
            "age":64
          },
          {
            "user":{
              "user_id":55389794,
              "first_name":"Jenny",
              "middle_name":null,
              "last_name":"Gump",
              "email":"jenny@gmail.com",
              "address":{"street":"234 Disco Trip Circle","city":"Los Angeles","state":"CA","zipcode":"90028","country_code":"US"},
              "dob":"1959-06-02",
              "gender":"F",
              "phone":"213-528-7078"
            },
            "event_id":661702,
            "bib_num":5,
            "age":63
          }
        ]
      }]'
      end

      let(:participants_response_body_page_2) do
        '[{
        "event":{"event_id":661702,"participants":[]},
        "participants":[
          {
            "user":{
              "user_id":18498798,
              "first_name":"Gilford",
              "middle_name":null,
              "last_name":"Granger",
              "email":"gilford@gmail.com",
              "address":{"street":"876 Main Street","city":"Boston","state":"MA","zipcode":"02123","country_code":"US"},
              "dob":"1998-01-01",
              "gender":"M",
              "phone":"776-583-3514"
              },
            "event_id":661702,
            "bib_num":13,
            "age":25
          },
          {
            "user":{
              "user_id":58758754,
              "first_name":"Yolanda",
              "middle_name":null,
              "last_name":"Yorgenson",
              "email":"yolanda@hotmail.com",
              "address":{"street":"76576 Harbinger","city":"Golan Heights","state":"MI","zipcode":"67584","country_code":"US"},
              "dob":"1988-11-11",
              "gender":"F",
              "phone":"535-528-7078"
            },
            "event_id":661702,
            "bib_num":15,
            "age":35
          }
        ]
      }]'
      end

      let(:participants_response_body_page_3) do
        '[{
        "event":{"event_id":661702,"participants":[]},
        "participants":[]
      }]'
      end

      let(:expected_result) do
        [
          ::Connectors::Runsignup::Models::Participant.new(
            first_name: "Bubba",
            last_name: "Gump",
            birthdate: "1958-01-01",
            gender: "male",
            bib_number: 3,
            city: "Atlanta",
            state_code: "GA",
            country_code: "US",
            email: "bubba@msn.com",
            phone: "404-583-3514",
            scheduled_start_time_local: "2/10/2023 18:00"
          ),
          ::Connectors::Runsignup::Models::Participant.new(
            first_name: "Jenny",
            last_name: "Gump",
            birthdate: "1959-06-02",
            gender: "female",
            bib_number: 5,
            city: "Los Angeles",
            state_code: "CA",
            country_code: "US",
            email: "jenny@gmail.com",
            phone: "213-528-7078",
            scheduled_start_time_local: "2/10/2023 18:00"
          ),
          ::Connectors::Runsignup::Models::Participant.new(
            first_name: "Gilford",
            last_name: "Granger",
            birthdate: "1998-01-01",
            gender: "male",
            bib_number: 13,
            city: "Boston",
            state_code: "MA",
            country_code: "US",
            email: "gilford@gmail.com",
            phone: "776-583-3514",
            scheduled_start_time_local: "2/10/2023 18:00"
          ),
          ::Connectors::Runsignup::Models::Participant.new(
            first_name: "Yolanda",
            last_name: "Yorgenson",
            birthdate: "1988-11-11",
            gender: "female",
            bib_number: 15,
            city: "Golan Heights",
            state_code: "MI",
            country_code: "US",
            email: "yolanda@hotmail.com",
            phone: "535-528-7078",
            scheduled_start_time_local: "2/10/2023 18:00"
          ),
        ]
      end

      it "returns participant structs" do
        expect(result).to eq(expected_result)
      end

      context "when gender is blank for a participant" do
        let(:participants_response_body_page_1) do
          '[{
        "event":{"event_id":661702,"participants":[]},
        "participants":[
          {
            "user":{
              "user_id":18423667,
              "first_name":"Bubba",
              "middle_name":null,
              "last_name":"Gump",
              "email":"bubba@msn.com",
              "address":{"street":"123 Main Street","city":"Atlanta","state":"GA","zipcode":"34343","country_code":"US"},
              "dob":"1958-01-01",
              "gender":null,
              "phone":"404-583-3514"
              },
            "event_id":661702,
            "bib_num":3,
            "age":64
          },
          {
            "user":{
              "user_id":55389794,
              "first_name":"Jenny",
              "middle_name":null,
              "last_name":"Gump",
              "email":"jenny@gmail.com",
              "address":{"street":"234 Disco Trip Circle","city":"Los Angeles","state":"CA","zipcode":"90028","country_code":"US"},
              "dob":"1959-06-02",
              "gender":"F",
              "phone":"213-528-7078"
            },
            "event_id":661702,
            "bib_num":5,
            "age":63
          }
        ]
      }]'
        end

        let(:expected_result) do
          [
            ::Connectors::Runsignup::Models::Participant.new(
              first_name: "Bubba",
              last_name: "Gump",
              birthdate: "1958-01-01",
              gender: "nonbinary",
              bib_number: 3,
              city: "Atlanta",
              state_code: "GA",
              country_code: "US",
              email: "bubba@msn.com",
              phone: "404-583-3514",
              scheduled_start_time_local: "2/10/2023 18:00"
            ),
            ::Connectors::Runsignup::Models::Participant.new(
              first_name: "Jenny",
              last_name: "Gump",
              birthdate: "1959-06-02",
              gender: "female",
              bib_number: 5,
              city: "Los Angeles",
              state_code: "CA",
              country_code: "US",
              email: "jenny@gmail.com",
              phone: "213-528-7078",
              scheduled_start_time_local: "2/10/2023 18:00"
            ),
            ::Connectors::Runsignup::Models::Participant.new(
              first_name: "Gilford",
              last_name: "Granger",
              birthdate: "1998-01-01",
              gender: "male",
              bib_number: 13,
              city: "Boston",
              state_code: "MA",
              country_code: "US",
              email: "gilford@gmail.com",
              phone: "776-583-3514",
              scheduled_start_time_local: "2/10/2023 18:00"
            ),
            ::Connectors::Runsignup::Models::Participant.new(
              first_name: "Yolanda",
              last_name: "Yorgenson",
              birthdate: "1988-11-11",
              gender: "female",
              bib_number: 15,
              city: "Golan Heights",
              state_code: "MI",
              country_code: "US",
              email: "yolanda@hotmail.com",
              phone: "535-528-7078",
              scheduled_start_time_local: "2/10/2023 18:00"
            ),
          ]
        end

        it "returns participant structs with nonbinary gender" do
          expect(result).to eq(expected_result)
        end
      end
    end

    context "when the race id or event id is not valid" do
      before { allow(client).to receive(:get_participants).with(race_id, event_id, anything).and_raise ::Connectors::Errors::NotFound }

      it { expect { result }.to raise_error ::Connectors::Errors::NotFound }
    end
  end
end
