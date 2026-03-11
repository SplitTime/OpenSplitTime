require "rails_helper"

RSpec.describe SyncTrackPointsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(course.id) }

  let(:course) { courses(:sum_100k_course) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "executes perform" do
    expect(::Interactors::SetTrackPoints).to receive(:perform!).with(course)
    perform_enqueued_jobs { job }
  end
end
