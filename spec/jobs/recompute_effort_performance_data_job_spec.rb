require "rails_helper"

RSpec.describe RecomputeEffortPerformanceDataJob do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

  def perturb_distance(effort)
    bits = effort.overall_performance.to_s
    field = (bits[15...45].to_i(2) + 1).to_s(2).rjust(30, "0")
    effort.update_columns(overall_performance: bits[0...15] + field + bits[45..])
  end

  describe "#perform" do
    it "restores consistency and touches the event and its efforts" do
      perturb_distance(effort)
      expect(event.performance_data_stale?).to be(true)

      described_class.perform_now([event.id])

      expect(event.performance_data_stale?).to be(false)
      expect(effort.reload.overall_performance).not_to be_nil
    end
  end

  describe ".enqueue_if_stale" do
    let(:authorized_user) { users(:admin_user) }
    let(:unauthorized_user) { users(:third_user) }

    it "enqueues when the user is authorized and the event is stale" do
      perturb_distance(effort)
      expect { described_class.enqueue_if_stale(event, authorized_user) }
        .to have_enqueued_job(described_class).with([event.id])
    end

    it "does not enqueue when the event is not stale" do
      expect { described_class.enqueue_if_stale(event, authorized_user) }
        .not_to have_enqueued_job(described_class)
    end

    it "does not enqueue for an unauthorized user" do
      perturb_distance(effort)
      expect { described_class.enqueue_if_stale(event, unauthorized_user) }
        .not_to have_enqueued_job(described_class)
    end

    it "does not enqueue for an anonymous user" do
      perturb_distance(effort)
      expect { described_class.enqueue_if_stale(event, nil) }
        .not_to have_enqueued_job(described_class)
    end
  end
end
