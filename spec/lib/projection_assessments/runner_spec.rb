require "rails_helper"

RSpec.describe ProjectionAssessments::Runner do
  subject { described_class.new(assessment_run) }

  let(:assessment_run) do
    event.projection_assessment_runs.create!(
      completed_lap: 1,
      completed_split_id: completed_split.id,
      completed_bitkey: SubSplit::OUT_BITKEY,
      projected_lap: 1,
      projected_split_id: projected_split.id,
      projected_bitkey: SubSplit::IN_BITKEY,
    )
  end
  let(:event) { events(:hardrock_2016) }
  let(:completed_split) { splits(:hardrock_cw_telluride) }
  let(:projected_split) { splits(:hardrock_cw_grouse) }

  describe "#perform!" do
    let(:assessment) { assessment_run.assessments.find_by(effort_id: effort.id) }
    before { subject.perform! }

    it "creates a number of projection_assessments equal to the effort count" do
      expect(assessment_run.assessments.count).to eq(event.efforts.count)
    end

    context "for an effort that has completed and projected split_times" do
      let(:effort) { efforts(:hardrock_2016_lavon_paucek) }

      it "sets expected attributes" do
        expect(assessment.projected_early).to eq("2016-07-15 19:29:48 -0600")
        expect(assessment.projected_best).to eq("2016-07-15 20:32:45 -0600")
        expect(assessment.projected_late).to eq("2016-07-15 21:35:41 -0600")
        expect(assessment.actual).to eq("2016-07-15 20:36:00 -0600")
      end
    end

    context "for an effort that has a completed split_time but no projected split_time" do
      let(:effort) { efforts(:hardrock_2016_rhett_auer) }

      it "sets expected attributes" do
        expect(assessment.projected_early).to eq("2016-07-15 18:30:26 -0600")
        expect(assessment.projected_best).to eq("2016-07-15 19:12:31 -0600")
        expect(assessment.projected_late).to eq("2016-07-15 19:54:36 -0600")
        expect(assessment.actual).to be_nil
      end
    end

    context "for an effort that has no completed split_time" do
      let(:effort) { efforts(:hardrock_2016_start_only) }

      it "sets expected attributes" do
        expect(assessment.projected_early).to be_nil
        expect(assessment.projected_best).to be_nil
        expect(assessment.projected_late).to be_nil
        expect(assessment.actual).to be_nil
      end
    end
  end
end
