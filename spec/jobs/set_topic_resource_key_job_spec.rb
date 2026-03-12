require "rails_helper"

RSpec.describe SetTopicResourceKeyJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(person) }

  let(:person) { people(:bruno_fadel) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "assigns the topic resource and saves the record" do
    # The job loads the person from the database,
    # so it will be a different object if we don't stub it
    allow(Person).to receive(:find).and_return(person)
    expect(person).to receive(:assign_topic_resource)
    expect(person).to receive(:save)
    perform_enqueued_jobs { job }
  end
end
