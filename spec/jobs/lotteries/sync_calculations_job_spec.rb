require "rails_helper"

RSpec.describe Lotteries::SyncCalculationsJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(lottery, current_user: user) }
  let(:lottery) { lotteries(:lottery_without_tickets) }
  let(:user) { users(:admin_user) }

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls Lotteries::SyncCalculations with the correct arguments" do
    expect(Lotteries::SyncCalculations).to receive(:perform!).with(lottery)
    perform_enqueued_jobs { job }
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end
end
