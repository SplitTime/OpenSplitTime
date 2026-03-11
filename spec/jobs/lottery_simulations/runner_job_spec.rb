require "rails_helper"

RSpec.describe LotterySimulations::RunnerJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(lottery_simulation_run.id) }

  let(:lottery_simulation_run) { lottery_simulation_runs(:lottery_simulation_run_one) }

  before { allow(LotterySimulations::Runner).to receive(:perform!) }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  it "queues the job" do
    expect { job }.to change(described_class.queue_adapter.enqueued_jobs, :size).by(1)
  end

  it "calls LotterySimulations::Runner with the correct arguments" do
    expect(LotterySimulations::Runner).to receive(:perform!).with(lottery_simulation_run)
    perform_enqueued_jobs { job }
  end
end
