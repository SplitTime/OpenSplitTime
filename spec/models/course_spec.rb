require "rails_helper"

RSpec.describe Course, type: :model do
  include BitkeyDefinitions

  it_behaves_like "auditable"
  it { is_expected.to strip_attribute(:name).collapse_spaces }
  it { is_expected.to strip_attribute(:description).collapse_spaces }
  it { is_expected.to localize_time_attribute(:next_start_time) }

  describe "#initialize" do
    let(:organization) { build_stubbed(:organization) }

    it "is valid with a name and organization" do
      course = build_stubbed(:course, organization: organization)
      expect(course).to be_valid
    end

    it "is invalid without a name" do
      course = build_stubbed(:course, name: nil, organization: organization)
      expect(course).not_to be_valid
      expect(course.errors[:name]).to include("can't be blank")
    end

    it "is invalid without an organization" do
      course = build_stubbed(:course, organization: nil)
      expect(course).not_to be_valid
      expect(course.errors[:organization]).to include("can't be blank")
    end

    it "does not allow duplicate names" do
      create(:course, name: "Hard Time 100")
      course = build(:course, name: "Hard Time 100")
      expect(course).not_to be_valid
      expect(course.errors[:name]).to include("has already been taken")
    end
  end

  describe "add_basic_splits" do
    let(:course) { build(:course) }
    it "adds a start and finish split to the course" do
      expect(course.splits.size).to eq(0)
      course.add_basic_splits!
      expect(course.splits.size).to eq(2)
      expect(course.splits.map(&:kind)).to eq(["start", "finish"])
    end

    it "returns the course" do
      expect(course.add_basic_splits!).to be_a(::Course)
    end
  end

  describe "#average_finish_seconds" do
    let(:result) { course.average_finish_seconds }
    let(:course) { courses(:hardrock_ccw) }

    before { EffortSegment.set_all }

    it "returns the average finish time in seconds for the course" do
      expect(result).to eq(139039)
    end
  end

  describe "methods that produce lap_splits" do
    let(:course) { courses(:rufa_course) }
    let(:splits) { course.ordered_splits }
    let(:split_ids) { splits.map(&:id) }

    describe "#cycled_lap_splits" do
      let(:lap_splits) { course.cycled_lap_splits.first(number) }

      context "when called with first(0)" do
        let(:number) { 0 }

        it "returns an empty array" do
          expect(lap_splits).to eq([])
        end
      end

      context "when called with a number greater than 0" do
        let(:number) { 8 }

        it "returns an array of that number of ordered TimePoints for the event" do
          expect(lap_splits.size).to eq(number)
          expect(lap_splits.map(&:lap)).to eq([1] * 3 + [2] * 3 + [3] * 2)
          expect(lap_splits.map(&:split_id)).to eq(split_ids * 2 + split_ids.first(2))
        end
      end
    end

    describe "#lap_splits_through" do
      let(:lap_splits) { course.lap_splits_through(laps) }

      context "when lap is 0" do
        let(:laps) { 0 }

        it "returns an empty array when called with first(0)" do
          expect(lap_splits).to eq([])
        end
      end

      context "when lap is greater than 0" do
        let(:laps) { 2 }

        it "returns an array of lap_splits through the provided lap number" do
          expect(lap_splits.size).to eq(laps * splits.size)
          expect(lap_splits.map(&:lap)).to eq([1] * 3 + [2] * 3)
          expect(lap_splits.map(&:split_id)).to eq(split_ids * 2)
        end
      end
    end
  end

  describe "methods that produce time_points" do
    let(:course) { courses(:rufa_course) }
    let(:splits) { course.ordered_splits }
    let(:split_ids) { splits.map(&:id) }

    describe "#cycled_time_points" do
      let(:time_points) { course.cycled_time_points.first(number) }

      context "when called with first(0)" do
        let(:number) { 0 }

        it "returns an empty array when called with first(0)" do
          expect(time_points).to eq([])
        end
      end

      context "when called with a number greater than 0" do
        let(:number) { 8 }

        it "returns an array of that number of ordered TimePoints for the event" do
          expect(time_points.size).to eq(number)
          expect(time_points.map(&:lap)).to eq([1] * 3 + [2] * 3 + [3] * 2)
          expect(time_points.map(&:split_id)).to eq(split_ids * 2 + split_ids.first(2))
          expect(time_points.map(&:bitkey)).to all eq(in_bitkey)
        end
      end
    end

    describe "#time_points_through" do
      let(:time_points) { course.time_points_through(laps) }

      context "when lap is 0" do
        let(:laps) { 0 }

        it "returns an empty array when called with first(0)" do
          expect(time_points).to eq([])
        end
      end

      context "when lap is greater than 0" do
        let(:laps) { 2 }

        it "returns an array of ordered TimePoints for that number of laps" do
          expect(time_points.size).to eq(laps * 3)
          expect(time_points.map(&:lap)).to eq([1] * 3 + [2] * 3)
          expect(time_points.map(&:split_id)).to eq(split_ids * 2)
          expect(time_points.map(&:bitkey)).to all eq(in_bitkey)
        end
      end
    end
  end

  describe "#distance" do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it "returns a course distance using the distance_from_start of the finish split" do
      expect(course.distance).to eq(finish_split.distance_from_start)
    end

    it "returns nil if no finish split exists on the course" do
      allow(course).to receive(:finish_split).and_return(nil)
      expect(course.distance).to be_nil
    end
  end

  describe "#track_points" do
    let(:course) { create(:course, :with_gpx) }
    context "when track points have been set" do
      before { ::Interactors::SetTrackPoints.perform!(course) }

      it "returns an array of hashes containing lat/lon points" do
        expect(course.track_points.count).to eq(113)
        expect(course.track_points.first).to eq("lat" => 39.627091, "lon" => -104.904226)
        expect(course.track_points.last).to eq("lat" => 39.623804, "lon" => -104.893363)
      end
    end

    context "when no track points have been set" do
      it "returns nil" do
        expect(course.track_points).to be_nil
      end
    end
  end

  describe "#vert_gain" do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it "returns a course vert_gain using the distance_from_start of the finish split" do
      expect(course.vert_gain).to eq(finish_split.vert_gain_from_start)
    end

    it "returns nil if no finish split exists on the course" do
      allow(course).to receive(:finish_split).and_return(nil)
      expect(course.vert_gain).to be_nil
    end
  end

  describe "#vert_loss" do
    let(:course) { courses(:rufa_course) }
    let(:finish_split) { course.finish_split }

    it "returns a course vert_loss using the distance_from_start of the finish split" do
      expect(course.vert_loss).to eq(finish_split.vert_loss_from_start)
    end

    it "returns nil if no finish split exists on the course" do
      allow(course).to receive(:finish_split).and_return(nil)
      expect(course.vert_loss).to be_nil
    end
  end

  describe "#simple?" do
    subject { course.simple? }
    let(:course) { build_stubbed(:course, splits: splits) }

    context "when the course has only a start and finish split" do
      let(:splits) { build_stubbed_list(:split, 2) }

      it "returns true" do
        expect(subject).to eq(true)
      end
    end

    context "when the course has more than two splits" do
      let(:splits) { build_stubbed_list(:split, 3) }

      it "returns false" do
        expect(subject).to eq(false)
      end
    end
  end
end
