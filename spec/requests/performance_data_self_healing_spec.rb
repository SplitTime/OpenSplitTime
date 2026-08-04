require "rails_helper"

RSpec.describe "performance data self-healing on page views" do
  include Warden::Test::Helpers

  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

  after { Warden.test_reset! }

  before do
    bits = effort.overall_performance.to_s
    field = (bits[15...45].to_i(2) + 1).to_s(2).rjust(30, "0")
    effort.update_columns(overall_performance: bits[0...15] + field + bits[45..])
  end

  context "when viewed by an authorized user" do
    before { login_as users(:admin_user), scope: :user }

    it "the spread enqueues a recompute for the event" do
      expect { get spread_event_path(event) }
        .to have_enqueued_job(RecomputeEffortPerformanceDataJob).with([event.id])
    end

    it "an effort page enqueues a recompute for the event" do
      expect { get effort_path(effort) }
        .to have_enqueued_job(RecomputeEffortPerformanceDataJob).with([event.id])
    end
  end

  context "when viewed anonymously" do
    it "the spread does not enqueue a recompute" do
      expect { get spread_event_path(event) }
        .not_to have_enqueued_job(RecomputeEffortPerformanceDataJob)
    end

    it "an effort page does not enqueue a recompute" do
      expect { get effort_path(effort) }
        .not_to have_enqueued_job(RecomputeEffortPerformanceDataJob)
    end
  end
end
