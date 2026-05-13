require "rails_helper"

RSpec.describe OrganizationUsageShowPresenter do
  let(:hardrock) { organizations(:hardrock) }

  describe "#chart_series" do
    it "groups counts by event group and year" do
      presenter = described_class.new(hardrock)

      expect(presenter.chart_series).not_to be_empty
      presenter.chart_series.each do |series|
        expect(series).to include(:name, :data)
        expect(series[:data]).not_to be_empty
        series[:data].each_key { |year| expect(year).to be_an(Integer) }
      end
    end

    it "is empty when all event groups are concealed" do
      hardrock.event_groups.update_all(concealed: true)
      presenter = described_class.new(hardrock)

      expect(presenter.chart_series).to be_empty
      expect(presenter.total_efforts).to eq(0)
    end
  end

  describe "#total_efforts" do
    it "counts only started efforts" do
      Effort.joins(event: :event_group)
            .where(event_groups: { organization_id: hardrock.id })
            .update_all(started: false)
      presenter = described_class.new(hardrock)

      expect(presenter.total_efforts).to eq(0)
    end

    it "matches the sum of all chart data points" do
      presenter = described_class.new(hardrock)

      chart_sum = presenter.chart_series.sum { |series| series[:data].values.sum }
      expect(presenter.total_efforts).to eq(chart_sum)
    end
  end
end
