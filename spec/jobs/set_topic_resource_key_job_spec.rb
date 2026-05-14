require "rails_helper"

RSpec.describe SetTopicResourceKeyJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(effort) }

  let(:effort) { efforts(:rufa_2017_12h_not_started) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "assigns the topic resource and saves the record" do
    # The job loads the effort from the database, so it will be a different
    # object than the let if we don't stub the lookup.
    allow(Effort).to receive(:find).and_return(effort)
    expect(effort).to receive(:assign_topic_resource)
    expect(effort).to receive(:save)
    perform_enqueued_jobs { job }
  end
end
