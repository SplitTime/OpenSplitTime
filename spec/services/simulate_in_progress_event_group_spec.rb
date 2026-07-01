require "rails_helper"

RSpec.describe SimulateInProgressEventGroup do
  subject(:result) do
    described_class.perform(source_event_group: source, cutoff_time: cutoff, count: count, current_time: current_time)
  end

  let(:source) { event_groups(:sum) }
  let(:count) { 50 }
  let(:current_time) { Time.zone.parse("2026-07-01 12:00:00") }
  # Anchor the cutoff to the latest recorded time so every started runner is included and the
  # newest simulated time lands at current_time.
  let(:cutoff) do
    SplitTime.joins(effort: :event).where(events: { event_group_id: source.id }).maximum(:absolute_time)
  end

  it "creates a concealed duplicate group distinct from the source" do
    expect(result.new_event_group).to be_persisted
    expect(result.new_event_group).to be_concealed
    expect(result.new_event_group.id).not_to eq(source.id)
    expect(result.new_event_group.name).to include("Simulated")
  end

  it "copies real split times (shifted so the newest lands at now) for started runners" do
    new_group = result.new_event_group
    new_split_times = SplitTime.joins(effort: :event).where(events: { event_group_id: new_group.id })

    expect(result.simulated_efforts_count).to be_positive
    expect(new_group.events.flat_map(&:efforts)).to all(be_started)
    expect(new_split_times.count).to be_positive
    expect(new_split_times.maximum(:absolute_time)).to be_within(1.second).of(current_time)
    expect(new_split_times.maximum(:absolute_time)).to be <= current_time
  end

  it "gives the simulated runners fabricated identities" do
    new_efforts = result.new_event_group.events.flat_map(&:efforts)

    expect(new_efforts).to all(have_attributes(first_name: be_present, last_name: be_present))
  end

  context "with a small count" do
    let(:count) { 1 }

    it "limits each event to `count` efforts" do
      expect(result.simulated_efforts_count).to be_positive
      expect(result.new_event_group.events.map { |event| event.efforts.count }).to all(be <= 1)
    end
  end
end
