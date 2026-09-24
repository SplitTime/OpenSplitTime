require "rails_helper"

RSpec.describe SyncEntrantsJob, type: :job do
  include ActiveJob::TestHelper

  let(:event) { events(:rufa_2017_24h) }
  let(:user) { users(:admin_user) }
  let(:import_job) do
    ImportJob.create!(parent: event, user: user, format: "runsignup", status: :waiting)
  end

  it "queues the job" do
    expect { described_class.perform_later(import_job.id) }
      .to have_enqueued_job(described_class).with(import_job.id)
  end

  it "delegates to SyncEntrantsRunner" do
    expect(SyncEntrantsRunner).to receive(:run!).with(an_instance_of(ImportJob))
    described_class.perform_now(import_job.id)
  end
end
