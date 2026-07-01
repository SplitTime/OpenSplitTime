require "rails_helper"

RSpec.describe SimulateInProgressEventGroup do
  subject(:result) do
    described_class.perform(source_event_group: source, start_time: start_time,
                            elapsed_seconds: elapsed_seconds, count: count)
  end

  let(:source) { event_groups(:sum) }
  let(:count) { 50 }
  let(:start_time) { Time.zone.parse("2026-07-01 06:00:00") }
  let(:elapsed_seconds) { 100.hours }

  it "creates a concealed duplicate group distinct from the source" do
    expect(result.new_event_group).to be_persisted
    expect(result.new_event_group).to be_concealed
    expect(result.new_event_group.id).not_to eq(source.id)
    expect(result.new_event_group.name).to include("Simulated")
  end

  it "places the group start at the requested start time" do
    expect(result.new_event_group.events.map(&:scheduled_start_time).min).to be_within(1.second).of(start_time)
  end

  it "copies started runners' real split times, shifted onto the new start" do
    new_split_times = SplitTime.joins(effort: :event).where(events: { event_group_id: result.new_event_group.id })

    expect(result.simulated_efforts_count).to be_positive
    expect(result.new_event_group.events.flat_map(&:efforts)).to all(be_started)
    expect(new_split_times.count).to be_positive
    # The earliest recorded time (the group start) shifts to the requested start time.
    expect(new_split_times.minimum(:absolute_time)).to be_within(1.second).of(start_time)
  end

  it "gives the simulated runners fabricated identities" do
    new_efforts = result.new_event_group.events.flat_map(&:efforts)

    expect(new_efforts).to all(have_attributes(first_name: be_present, last_name: be_present))
  end

  context "with a short elapsed cutoff" do
    let(:elapsed_seconds) { 6.hours }

    it "keeps every simulated time at or before the elapsed moment" do
      new_times = SplitTime.joins(effort: :event).where(events: { event_group_id: result.new_event_group.id })

      expect(result.simulated_efforts_count).to be_positive
      expect(new_times.pluck(:absolute_time)).to all(be <= start_time + elapsed_seconds)
    end
  end

  context "with a small count" do
    let(:count) { 1 }

    it "limits each event to `count` efforts" do
      expect(result.simulated_efforts_count).to be_positive
      expect(result.new_event_group.events.map { |event| event.efforts.count }).to all(be <= 1)
    end
  end
end
