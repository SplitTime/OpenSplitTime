# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncTrackPointsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(course.id) }
  let(:course) { courses(:sum_100k_course) }

  it "queues the job" do
    expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "uses the default queue" do
    expect(SyncTrackPointsJob.new.queue_name).to eq("default")
  end

  it "executes perform" do
    expect(::Interactors::SetTrackPoints).to receive(:perform!).with(course)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
