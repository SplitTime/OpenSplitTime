require "rails_helper"

RSpec.describe StartEffortsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(task, effort_ids: effort_ids, start_time: start_time, current_user: current_user) }

  let(:task) do
    AsyncTask.create!(
      parent: event_group,
      user: current_user,
      job_class: "StartEffortsJob",
      context_key: "2017-09-23T14:00:00Z",
      description: "Starting 2 entrants",
    )
  end
  let(:event_group) { event_groups(:sum) }
  let(:subject_efforts) { [efforts(:sum_55k_not_started), efforts(:sum_100k_un_started)] }
  let(:effort_ids) { subject_efforts.map(&:id) }
  let(:start_time) { "2017-09-23 08:00:00" }
  let(:current_user) { users(:admin_user) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls StartEfforts and UpdateEffortsStatus" do
    expect(Interactors::StartEfforts).to receive(:perform!).and_call_original
    expect(Interactors::UpdateEffortsStatus).to receive(:perform!).and_call_original
    perform_enqueued_jobs { job }
  end

  it "creates starting split times for the given efforts" do
    expect { perform_enqueued_jobs { job } }.to change(SplitTime, :count).by(2)

    subject_efforts.each(&:reload)
    expect(subject_efforts.map(&:starting_split_time)).to all be_present
  end

  it "marks the task finished" do
    perform_enqueued_jobs { job }
    expect(task.reload).to be_finished
  end

  it "broadcasts a completion flash and a start button replace" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      event_group,
      target: "flash",
      partial: "layouts/broadcast_flash",
      locals: hash_including(level: :success, message: /Started 2 efforts/),
    )
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      event_group,
      target: "start_ready_efforts_button_event_group_#{event_group.id}",
      partial: "event_groups/start_ready_efforts_button",
      locals: hash_including(presenter: instance_of(EventGroupStartPresenter)),
    )
    perform_enqueued_jobs { job }
  end

  context "when the interactor response is unsuccessful" do
    let(:start_time) { "not a parsable time" }

    it "marks the task failed with an error message and broadcasts a danger flash" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        event_group,
        target: "flash",
        partial: "layouts/broadcast_flash",
        locals: hash_including(level: :danger),
      )
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        event_group,
        target: "start_ready_efforts_button_event_group_#{event_group.id}",
        partial: anything,
        locals: anything,
      )
      expect { perform_enqueued_jobs { job } }.not_to change(SplitTime, :count)

      task.reload
      expect(task).to be_failed
      expect(task.error_message).to be_present
    end
  end
end
