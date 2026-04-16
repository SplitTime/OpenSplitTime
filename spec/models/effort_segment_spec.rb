require "rails_helper"

RSpec.describe EffortSegment do
  let(:effort_1) { efforts(:hardrock_2015_tuan_jacobs) }
  let(:effort_2) { efforts(:hardrock_2015_erich_larson) }

  describe ".delete_for_effort" do
    before do
      effort_1.set_effort_segments
      effort_2.set_effort_segments
    end

    it "deletes all effort_segments for the indicated effort" do
      expect { described_class.delete_for_effort(effort_1) }.to change(described_class, :count).from(182).to(91)
    end

    it "does not delete effort_segments for other efforts" do
      expect do
        described_class.delete_for_effort(effort_1)
      end.not_to(change { effort_2.effort_segments.count })
    end
  end

  describe ".delete_for_split_time" do
    let(:split_time_1) { effort_1.split_times.last }
    let(:split_time_2) { effort_2.split_times.last }

    before do
      effort_1.set_effort_segments
      effort_2.set_effort_segments
    end

    it "deletes all effort_segments for the split_time" do
      expect do
        described_class.delete_for_split_time(split_time_1)
      end.to change { effort_1.effort_segments.count }.from(91).to(78)
    end

    it "does not delete effort_segments for other split_times" do
      expect do
        described_class.delete_for_split_time(split_time_1)
      end.not_to(change { effort_2.effort_segments.count })
    end
  end

  describe ".set_all" do
    it "sets effort_segments for all efforts" do
      expect { described_class.set_all }.to change(described_class, :count).from(0).to(4530)
    end
  end

  describe ".set_for_effort" do
    it "sets effort_segments for the indicated effort" do
      expect { described_class.set_for_effort(effort_1) }.to change { effort_1.effort_segments.count }.from(0).to(91)
    end

    it "does not set effort_segments for other efforts" do
      expect { described_class.set_for_effort(effort_1) }.not_to(change { effort_2.effort_segments.count })
    end
  end

  describe ".set_for_split_time" do
    let(:split_time_1) { effort_1.split_times.last }
    let(:split_time_2) { effort_2.split_times.last }

    it "sets effort_segments for the split_time" do
      expect do
        described_class.set_for_split_time(split_time_1)
      end.to change { effort_1.effort_segments.count }.from(0).to(13)
    end

    it "does not set effort_segments for other split_times" do
      expect do
        described_class.set_for_split_time(split_time_1)
      end.not_to(change { effort_2.effort_segments.count })
    end

    context "when a split_time has a pathological absolute_time that would overflow int32 elapsed_seconds" do
      before do
        # Force a ~100 year elapsed_seconds, well beyond 32-bit int range (~68 years).
        split_time_1.update_columns(absolute_time: effort_1.split_times.first.absolute_time + 100.years)
        split_time_1.send(:sync_elapsed_seconds)
      end

      it "skips the overflowing segments rather than raising RangeError" do
        expect { described_class.set_for_effort(effort_1) }.not_to raise_error
        # Segments not involving the poisoned split_time should still be created.
        expect(effort_1.effort_segments.count).to be > 0
        expect(effort_1.effort_segments.pluck(:elapsed_seconds).max).to be <= 2_147_483_647
        # Segments involving the poisoned split_time (as end_split) should have been filtered out.
        expect(effort_1.effort_segments.where(end_split_id: split_time_1.split_id,
                                              end_bitkey: split_time_1.bitkey,
                                              lap: split_time_1.lap)).to be_empty
      end
    end
  end
end
