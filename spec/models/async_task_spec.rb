require "rails_helper"

RSpec.describe AsyncTask, kind: :model do
  describe ".active" do
    subject { described_class.active }

    it "includes in_progress tasks created within the staleness threshold" do
      expect(subject).to include(async_tasks(:sum_start_efforts_in_progress))
      expect(subject).to include(async_tasks(:hardrock_2016_status_update_in_progress))
    end

    it "excludes in_progress tasks older than the staleness threshold" do
      expect(subject).not_to include(async_tasks(:sum_start_efforts_stale))
    end

    it "excludes tasks that are not in_progress" do
      expect(subject).not_to include(async_tasks(:sum_start_efforts_finished))
    end
  end

  describe ".active_for?" do
    let(:event_group) { event_groups(:sum) }

    context "when an active task exists for the parent, job_class, and context_key" do
      it "returns true" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: "StartEffortsJob",
          context_key: "2017-09-23T13:00:00Z",
        )
        expect(result).to be(true)
      end
    end

    context "when the matching task is stale" do
      it "returns false" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: "StartEffortsJob",
          context_key: "2017-09-23T14:00:00Z",
        )
        expect(result).to be(false)
      end
    end

    context "when the matching task is finished" do
      it "returns false" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: "StartEffortsJob",
          context_key: "2017-09-23T12:00:00Z",
        )
        expect(result).to be(false)
      end
    end

    context "when no task exists for the context_key" do
      it "returns false" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: "StartEffortsJob",
          context_key: "2017-09-23T15:00:00Z",
        )
        expect(result).to be(false)
      end
    end

    context "when the job_class does not match" do
      it "returns false" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: "UpdateEffortsStatusJob",
          context_key: "2017-09-23T13:00:00Z",
        )
        expect(result).to be(false)
      end
    end

    context "when the parent does not match" do
      it "returns false" do
        result = described_class.active_for?(
          parent: event_groups(:hardrock_2016),
          job_class: "StartEffortsJob",
          context_key: "2017-09-23T13:00:00Z",
        )
        expect(result).to be(false)
      end
    end

    context "when context_key is nil" do
      it "matches only tasks having a nil context_key" do
        expect(described_class.active_for?(parent: event_groups(:hardrock_2016), job_class: "UpdateEffortsStatusJob")).to be(true)
        expect(described_class.active_for?(parent: event_group, job_class: "StartEffortsJob")).to be(false)
      end
    end

    context "when job_class is passed as a class" do
      it "matches by the class name" do
        result = described_class.active_for?(
          parent: event_group,
          job_class: ActiveJob::Base,
          context_key: "any",
        )
        expect(result).to be(false)
        expect(described_class.active.where(job_class: "StartEffortsJob", parent: event_group)).to be_present
      end
    end
  end

  describe "validations" do
    subject(:async_task) { described_class.new(parent: event_groups(:sum), job_class: "StartEffortsJob") }

    it "is valid with a parent and a job_class" do
      expect(async_task).to be_valid
    end

    it "is invalid without a job_class" do
      async_task.job_class = nil
      expect(async_task).not_to be_valid
      expect(async_task.errors[:job_class]).to include("can't be blank")
    end

    it "is invalid without a parent" do
      async_task.parent = nil
      expect(async_task).not_to be_valid
      expect(async_task.errors[:parent]).to include("must exist")
    end

    it "is valid without a user and without a context_key" do
      expect(async_task.user).to be_nil
      expect(async_task.context_key).to be_nil
      expect(async_task).to be_valid
    end
  end
end
