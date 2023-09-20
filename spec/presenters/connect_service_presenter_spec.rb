# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConnectServicePresenter do
  let(:presenter) { described_class.new(event_group, service, view_context) }
  let(:event_group) { event_groups(:ramble) }
  let(:service) { ::Connectors::Service::BY_IDENTIFIER[:rattlesnake_ramble] }
  let(:view_context) { ActionController::Base.new.view_context }
  let(:user) { users(:third_user) }
  let(:ramble_events) do
    [
      ::Connectors::RattlesnakeRamble::Models::RaceEdition.new(id: 1, date: "2022-09-01", race_name: "Full Course Even Years"),
      ::Connectors::RattlesnakeRamble::Models::RaceEdition.new(id: 2, date: "2022-09-01", race_name: "Kids Course"),
      ::Connectors::RattlesnakeRamble::Models::RaceEdition.new(id: 3, date: "2023-09-05", race_name: "Full Course Odd Years"),
      ::Connectors::RattlesnakeRamble::Models::RaceEdition.new(id: 4, date: "2023-09-05", race_name: "Kids Course"),
    ]
  end
  let(:runsignup_events) { [] }

  before do
    allow(view_context).to receive(:current_user).and_return(user)
    allow(::Connectors::RattlesnakeRamble::FetchRaceEditions).to receive(:perform).and_return(ramble_events)
    allow(::Connectors::Runsignup::FetchRaceEvents).to receive(:perform).and_return(runsignup_events)
  end

  describe "#initialize" do
    it { expect { presenter }.not_to raise_error }

    it "does not send a message to connectors" do
      expect(::Connectors::RattlesnakeRamble::FetchRaceEditions).not_to receive(:perform)
      expect(::Connectors::Runsignup::FetchRaceEvents).not_to receive(:perform)
      presenter
    end
  end

  describe "#all_credentials_present?" do
    let(:result) { presenter.all_credentials_present? }

    context "when the user has credentials for the service" do
      it { expect(result).to eq(true) }
    end

    context "when the user is missing any credential for the service" do
      before { user.credentials.for_service(service.identifier).first.destroy! }

      it { expect(result).to eq(false) }
    end
  end

  describe "#error_message" do
    context "when credentials are present" do
      it "sends a message to the relevant connector" do
        expect(::Connectors::RattlesnakeRamble::FetchRaceEditions).to receive(:perform).with(user: user)
        expect(::Connectors::Runsignup::FetchRaceEvents).not_to receive(:perform)
        presenter.error_message
      end

      it "caches the call to the relevant connector" do
        expect(::Connectors::RattlesnakeRamble::FetchRaceEditions).to receive(:perform).with(user: user).once
        expect(::Connectors::Runsignup::FetchRaceEvents).not_to receive(:perform)
        2.times { presenter.error_message }
      end
    end

    context "when credentials are not present" do
      let(:user) { users(:admin_user) }

      it "does not send a message to any connector" do
        expect(::Connectors::RattlesnakeRamble::FetchRaceEditions).not_to receive(:perform)
        expect(::Connectors::Runsignup::FetchRaceEvents).not_to receive(:perform)
        presenter.error_message
      end
    end
  end

  describe "#no_sources_found?" do
    let(:result) { presenter.no_sources_found? }

    context "when events are returned" do
      it { expect(result).to eq(false) }
    end

    context "when events are not returned" do
      let(:ramble_events) { [] }

      it { expect(result).to eq(true) }
    end
  end

  describe "#no_sources_in_time_frame?" do
    let(:result) { presenter.no_sources_in_time_frame? }

    context "when any external event dates are close to the date of any event" do
      before { event_group.events.first.update(scheduled_start_time: "2023-09-05") }

      it { expect(result).to eq(false) }
    end

    context "when no external event dates are close to the date of any event" do
      it { expect(result).to eq(true) }
    end
  end

  describe "#sources_for_event" do
    let(:result) { presenter.sources_for_event(event) }
    let(:event) { event_group.events.first }

    it "caches the call to the relevant connector" do
      expect(::Connectors::RattlesnakeRamble::FetchRaceEditions).to receive(:perform).with(user: user).once
      expect(::Connectors::Runsignup::FetchRaceEvents).not_to receive(:perform)
      2.times { presenter.sources_for_event(event) }
    end

    context "when the event start time is close to the external event date" do
      before { event.update(scheduled_start_time: "2023-09-05") }

      it "returns the external events that are close to the event start time" do
        expect(result).to eq(ramble_events.last(2))
      end
    end

    context "when the event start time is not close to any external event date" do
      it { expect(result).to eq([]) }
    end
  end
end
