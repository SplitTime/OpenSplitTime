require "rails_helper"

RSpec.describe Interactors::EnqueueStartEfforts do
  include ActiveJob::TestHelper

  subject do
    described_class.new(event_group: event_group, filter: filter, start_time: start_time, current_user: current_user)
  end

  let(:event_group) { event_groups(:hardrock_2014) }
  let(:effort) { efforts(:hardrock_2014_not_started) }
  let(:filter) { { ready_to_start: true, assumed_start_time: assumed_start_time } }
  let(:assumed_start_time) { "2014-07-11 12:00:00 UTC" }
  let(:start_time) { "2014-07-11 06:02:00" }
  let(:current_user) { users(:admin_user) }

  before { effort.update(checked_in: true) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  context "when matching efforts exist and no task is active" do
    it "creates an active AsyncTask keyed to the assumed start time" do
      expect { subject.perform! }.to change(AsyncTask, :count).by(1)

      task = AsyncTask.last
      expect(task.parent).to eq(event_group)
      expect(task.user).to eq(current_user)
      expect(task.job_class).to eq("StartEffortsJob")
      expect(task.context_key).to eq("2014-07-11T12:00:00Z")
      expect(task.description).to eq("Starting 1 entrant")
      expect(task).to be_in_progress
    end

    it "enqueues StartEffortsJob with the resolved effort ids" do
      subject.perform!

      expect(StartEffortsJob).to have_been_enqueued.with(
        AsyncTask.last,
        effort_ids: [effort.id],
        start_time: start_time,
        current_user: current_user,
      )
    end

    it "returns a successful response with a starting message" do
      response = subject.perform!

      expect(response).to be_successful
      expect(response.message).to eq("Starting 1 entrant. This may take a minute for large events.")
    end
  end

  context "when no efforts match the filter" do
    let(:filter) { { ready_to_start: true, assumed_start_time: "2020-01-01 12:00:00 UTC" } }

    it "does not create a task or enqueue a job and returns an unsuccessful response" do
      response = nil
      expect { response = subject.perform! }.not_to change(AsyncTask, :count)

      expect(StartEffortsJob).not_to have_been_enqueued
      expect(response).not_to be_successful
      expect(response.message).to eq("No entrants were found to start.")
    end
  end

  context "when an active task exists for the same start time" do
    before do
      AsyncTask.create!(
        parent: event_group,
        job_class: "StartEffortsJob",
        context_key: "2014-07-11T12:00:00Z",
        description: "Starting 1 entrant",
      )
    end

    it "does not create a task or enqueue a job and returns an unsuccessful response" do
      response = nil
      expect { response = subject.perform! }.not_to change(AsyncTask, :count)

      expect(StartEffortsJob).not_to have_been_enqueued
      expect(response).not_to be_successful
      expect(response.message).to eq("Entrants for this start time are already being started.")
    end

    context "when the active task is stale" do
      before { AsyncTask.last.update_column(:created_at, 1.hour.ago) }

      it "enqueues a new task" do
        expect { subject.perform! }.to change(AsyncTask, :count).by(1)
        expect(StartEffortsJob).to have_been_enqueued
      end
    end
  end

  context "when the filter has no assumed start time" do
    let(:filter) { { ready_to_start: true } }

    it "creates a task with a nil context key and enqueues the job" do
      response = nil
      expect { response = subject.perform! }.to change(AsyncTask, :count).by(1)

      expect(AsyncTask.last.context_key).to be_nil
      expect(StartEffortsJob).to have_been_enqueued
      expect(response).to be_successful
    end
  end

  context "when the assumed start time is not parsable" do
    let(:assumed_start_time) { "99:99:99" }

    it "derives a nil context key rather than raising" do
      expect(subject.send(:context_key)).to be_nil
    end
  end
end
