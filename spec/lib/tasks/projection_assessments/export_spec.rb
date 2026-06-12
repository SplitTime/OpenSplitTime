require "rails_helper"
require "rake"
require "tempfile"

RSpec.describe "projection_assessments:export", type: :task do
  let(:task_name) { "projection_assessments:export" }

  before do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == task_name }
    Rake::Task[task_name].reenable
  end

  # The task interface is ENV-driven, so the spec must write ENV to exercise it.
  # rubocop:disable Rails/EnvironmentVariableAccess
  def with_env(values)
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    values.each_key { |key| ENV.delete(key) }
  end
  # rubocop:enable Rails/EnvironmentVariableAccess

  def silent_invoke
    suppress_output { Rake::Task[task_name].invoke }
  end

  def suppress_output
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    yield
  ensure
    $stdout = original_stdout
    $stderr = original_stderr
  end

  context "with valid arguments" do
    it "runs an assessment and writes a CSV of predictions and actuals" do
      Tempfile.open(["assessments", ".csv"]) do |file|
        env = {
          "EVENTS" => events(:hardrock_2016).slug,
          "COMPLETED_SPLIT" => "Telluride",
          "PROJECTED_SPLIT" => "Grouse",
          "OUTPUT" => file.path,
        }

        with_env(env) do
          expect { silent_invoke }.to change(ProjectionAssessmentRun, :count).by(1)
        end

        run = ProjectionAssessmentRun.last
        expect(run.event).to eq(events(:hardrock_2016))
        expect(run.completed_split).to eq(splits(:hardrock_cw_telluride))
        expect(run.completed_bitkey).to eq(SubSplit::OUT_BITKEY)
        expect(run.projected_split).to eq(splits(:hardrock_cw_grouse))
        expect(run.projected_bitkey).to eq(SubSplit::IN_BITKEY)
        expect(run).to be_finished

        table = CSV.read(file.path, headers: true)
        expect(table.headers).to eq(["Runner name", "Race year", "Earliest predicted arrival", "Actual arrival"])

        # Expected values match the assessments verified in projection_assessments/runner_spec.rb
        completed_and_projected = table.find { |row| row["Runner name"] == efforts(:hardrock_2016_lavon_paucek).full_name }
        expect(completed_and_projected["Race year"]).to eq("2016")
        expect(completed_and_projected["Earliest predicted arrival"]).to eq("2016-07-15 19:29:48")
        expect(completed_and_projected["Actual arrival"]).to eq("2016-07-15 20:36:00")

        completed_only = table.find { |row| row["Runner name"] == efforts(:hardrock_2016_rhett_auer).full_name }
        expect(completed_only["Earliest predicted arrival"]).to be_present
        expect(completed_only["Actual arrival"]).to be_nil

        no_prediction = table.find { |row| row["Runner name"] == efforts(:hardrock_2016_start_only).full_name }
        expect(no_prediction).to be_nil
      end
    end
  end

  context "when no projections are available" do
    it "includes rows with actual times and blank predictions" do
      Tempfile.open(["assessments", ".csv"]) do |file|
        env = {
          "EVENTS" => events(:hardrock_2016).slug,
          "COMPLETED_SPLIT" => "Telluride",
          "PROJECTED_SPLIT" => "Grouse",
          "OUTPUT" => file.path,
        }

        allow(Projection).to receive(:execute_query).and_return([])
        with_env(env) { silent_invoke }

        table = CSV.read(file.path, headers: true)

        no_prediction = table.find { |row| row["Runner name"] == efforts(:hardrock_2016_lavon_paucek).full_name }
        expect(no_prediction["Earliest predicted arrival"]).to be_nil
        expect(no_prediction["Actual arrival"]).to eq("2016-07-15 20:36:00")

        no_anchor = table.find { |row| row["Runner name"] == efforts(:hardrock_2016_start_only).full_name }
        expect(no_anchor).to be_nil
      end
    end
  end

  context "with missing arguments" do
    it "aborts with usage instructions" do
      expect { silent_invoke }.to raise_error(SystemExit)
    end
  end
end
