require "rails_helper"

RSpec.describe EffortShowView do
  subject { EffortShowView.new(effort) }
  let(:effort) { efforts(:hardrock_2014_progress_sherman) }
  let(:other_effort_1) { efforts(:hardrock_2014_ken_bradtke) }
  let(:other_effort_2) { efforts(:hardrock_2014_major_green) }

  describe "#next_problem_effort" do
    context "when the current effort is a problem effort" do
      before { effort.questionable! }

      context "when other problem efforts exist" do
        before do
          other_effort_1.bad!
          other_effort_2.bad!
        end

        context "when the current effort is not last alphabetically" do
          before { effort.update(last_name: "Carlisle") }

          it "returns the next problem effort alphabetically by last name" do
            expect(subject.next_problem_effort).to eq(other_effort_2)
          end
        end

        context "when the current effort is last alphabetically" do
          before { effort.update(last_name: "Zyzyx") }

          it "returns the first problem effort" do
            expect(subject.next_problem_effort).to eq(other_effort_1)
          end
        end
      end

      context "when no other problem efforts exist" do
        it "returns nil" do
          expect(subject.next_problem_effort).to be_nil
        end
      end
    end

    context "when the current effort is not a problem effort" do
      context "when other problem efforts exist" do
        before do
          other_effort_1.bad!
          other_effort_2.bad!
        end

        it "returns the first problem effort alphabetically by last name" do
          expect(subject.next_problem_effort).to eq(other_effort_1)
        end
      end

      context "when no other problem efforts exist" do
        it "returns nil" do
          expect(subject.next_problem_effort).to be_nil
        end
      end
    end
  end
end
