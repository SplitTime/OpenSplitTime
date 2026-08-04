require "rails_helper"

RSpec.describe RepairStalePerformanceDataJob do
  let(:event) { events(:hardrock_2015) }
  let(:effort) { efforts(:hardrock_2015_tuan_jacobs) }

  def perturb_distance(effort)
    bits = effort.overall_performance.to_s
    field = (bits[15...45].to_i(2) + 1).to_s(2).rjust(30, "0")
    effort.update_columns(overall_performance: bits[0...15] + field + bits[45..])
  end

  it "heals stale events and reports them as healed" do
    perturb_distance(effort)

    expect { described_class.perform_now }
      .to have_enqueued_mail(AdminMailer, :job_report)
      .with(described_class.name, a_string_including("Healed:\n#{event.slug}"))
    expect(event.performance_data_stale?).to be(false)
  end

  it "issues no recomputes and reports a clean run when no events are stale" do
    expect(Results::SetEffortPerformanceData).not_to receive(:perform!)

    expect { described_class.perform_now }
      .to have_enqueued_mail(AdminMailer, :job_report)
      .with(described_class.name, a_string_including("no stale events"))
  end

  it "reports an event that fails to heal" do
    perturb_distance(effort)
    allow(Results::SetEffortPerformanceData).to receive(:perform!)

    expect { described_class.perform_now }
      .to have_enqueued_mail(AdminMailer, :job_report)
      .with(described_class.name, a_string_including("#{event.slug}: still stale after recompute"))
  end

  it "reports the error when a recompute raises" do
    perturb_distance(effort)
    allow(Results::SetEffortPerformanceData).to receive(:perform!).and_raise(ActiveRecord::StatementInvalid, "boom")

    expect { described_class.perform_now }
      .to have_enqueued_mail(AdminMailer, :job_report)
      .with(described_class.name, a_string_including("#{event.slug}: boom"))
  end
end
