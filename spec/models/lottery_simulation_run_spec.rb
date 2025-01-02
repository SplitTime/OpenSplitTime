require "rails_helper"

RSpec.describe LotterySimulationRun, type: :model do
  describe "#set_context!" do
    subject { create(:lottery_simulation_run, lottery: lottery) }
    let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }

    before { subject.set_context! }
    let(:expected_context) do
      {
        "Elses" => {
          "slots"=>{"accepted"=>3, "wait_list"=>5},
          "entered"=>{"male"=>2, "female"=>3},
          "pre_selected"=>{"male"=>0, "female"=>0}
        },
        "Never Ever Evers" => {
          "slots"=>{"accepted"=>3, "wait_list"=>2},
          "entered"=>{"male"=>3, "female"=>3},
          "pre_selected"=>{"male"=>0, "female"=>0},
        },
        "Veterans" => {
          "slots"=>{"accepted"=>3, "wait_list"=>3},
          "entered"=>{"male"=>3, "female"=>1},
          "pre_selected"=>{"male"=>0, "female"=>0},
        },
      }
    end

    it "sets the context attribute" do
      expect(subject.context).to eq(expected_context)
    end
  end

  describe "time related methods" do
    subject { build(:lottery_simulation_run, started_at: started_at) }
    let(:started_at) { nil }

    before { travel_to test_start_time }

    describe "#set_elapsed_time!" do
      let(:test_start_time) { Time.current }
      context "when the record has not been persisted" do
        context "when started at time has not been set" do
          it "does not set elapsed time" do
            subject.set_elapsed_time!
            expect(subject.elapsed_time).to be_nil
          end
        end

        context "when started at time has been set" do
          before { subject.assign_attributes(started_at: 30.seconds.ago) }
          it "does not set elapsed time" do
            subject.set_elapsed_time!
            expect(subject.elapsed_time).to be_nil
          end
        end
      end

      context "when the record has been persisted" do
        before { subject.save! }
        context "when started at time has not been set" do
          it "does not set elapsed time" do
            subject.set_elapsed_time!
            expect(subject.elapsed_time).to be_nil
          end
        end

        context "when started at time has been set" do
          before { subject.update(started_at: 30.seconds.ago) }
          it "sets elapsed time to the amount of time that has passed" do
            subject.set_elapsed_time!
            expect(subject.elapsed_time).to eq(30)
          end
        end
      end
    end

    describe "#start!" do
      let(:test_start_time) { "2021-10-31 10:00:00".in_time_zone }
      context "when the import job has not been started" do
        it "sets start time as expected" do
          subject.start!
          expect(subject.started_at).to eq(test_start_time)
        end
      end

      context "when the import job has already been started" do
        let(:started_at) { 2.minutes.ago }
        it "overwrites the existing start time" do
          subject.start!
          expect(subject.started_at).to eq(test_start_time)
        end
      end
    end
  end
end
