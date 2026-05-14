require "rails_helper"
require "rake"
require "tempfile"

RSpec.describe "maintenance:import_monetary_donations", type: :task do
  let(:task_name) { "maintenance:import_monetary_donations" }
  let(:hardrock_id) { organizations(:hardrock).id }
  let(:running_up_id) { organizations(:running_up_for_air).id }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == task_name }
    Rake::Task[task_name].reenable
  end

  def with_csv(rows)
    Tempfile.open(["donations", ".csv"]) do |file|
      CSV.open(file.path, "w") do |csv|
        csv << ["Organization Name", "Organization ID", "Date", "Amount", "Source", "Notes"]
        rows.each { |row| csv << row }
        # File handle stays open through .write; .close ensures flush before tests read it.
        csv.flush if csv.respond_to?(:flush)
      end
      yield file.path
    end
  end

  def silent_invoke(path)
    suppress_output { Rake::Task[task_name].invoke(path) }
  end

  def suppress_output
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  it "creates donations for each CSV row" do
    with_csv([
               ["Hardrock", hardrock_id, "2024-09-12", "250.00", "paypal", "Order #1"],
               ["Running Up For Air", running_up_id, "2025-03-04", "75.50", "check", nil],
             ]) do |path|
      expect { silent_invoke(path) }.to change(MonetaryDonation, :count).by(2)

      latest = MonetaryDonation.order(created_at: :desc).first
      expect(latest.amount).to eq(75.50)
      expect(latest.source).to eq("check")
    end
  end

  it "skips rows that exactly match an existing donation (idempotent re-run)" do
    rows = [["Hardrock", hardrock_id, "2024-09-12", "250.00", "paypal", "Order #1"]]

    with_csv(rows) do |path|
      silent_invoke(path)
      Rake::Task[task_name].reenable
      expect { silent_invoke(path) }.not_to change(MonetaryDonation, :count)
    end
  end

  it "creates a donation when only the note differs from an existing one" do
    with_csv([["Hardrock", hardrock_id, "2024-09-12", "250.00", "paypal", "First note"]]) do |path|
      silent_invoke(path)
    end
    Rake::Task[task_name].reenable

    with_csv([["Hardrock", hardrock_id, "2024-09-12", "250.00", "paypal", "Different note"]]) do |path|
      expect { silent_invoke(path) }.to change(MonetaryDonation, :count).by(1)
    end
  end

  it "aborts and rolls back when an organization id is missing" do
    bogus_id = Organization.maximum(:id).to_i + 999
    with_csv([
               ["Hardrock", hardrock_id, "2024-09-12", "250.00", "paypal", "Good"],
               ["Phantom", bogus_id, "2024-09-13", "50.00", "check", nil],
             ]) do |path|
      expect { silent_invoke(path) }.to raise_error(SystemExit, /organization .* not found/)
                                    .and not_change(MonetaryDonation, :count)
    end
  end

  it "aborts on unknown source values" do
    with_csv([["Hardrock", hardrock_id, "2024-09-12", "250.00", "wire", nil]]) do |path|
      expect { silent_invoke(path) }.to raise_error(SystemExit, /unknown source/)
                                    .and not_change(MonetaryDonation, :count)
    end
  end

  it "aborts when required headers are missing" do
    Tempfile.open(["bad", ".csv"]) do |file|
      File.write(file.path, "Organization ID,Date\n#{hardrock_id},2024-09-12\n")

      expect { silent_invoke(file.path) }.to raise_error(SystemExit, /missing required columns/)
    end
  end

  it "aborts when no path is given" do
    expect { silent_invoke("") }.to raise_error(SystemExit, /Usage/)
  end

  it "aborts when the file does not exist" do
    expect { silent_invoke("/tmp/definitely_not_here_#{SecureRandom.hex}.csv") }
      .to raise_error(SystemExit, /File not found/)
  end
end
