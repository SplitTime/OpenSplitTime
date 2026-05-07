require "rails_helper"

RSpec.describe SyncEntrantsRunner do
  subject(:run!) { described_class.run!(import_job) }

  let(:event) { events(:rufa_2017_24h) }
  let(:user) { users(:admin_user) }
  let(:import_job) do
    ImportJob.create!(parent: event, user: user, format: "runsignup", status: :waiting)
  end

  let(:successful_response) do
    Interactors::Response.new(
      [],
      "Sync completed successfully",
      created_efforts: [Object.new, Object.new],
      updated_efforts: [Object.new],
      ignored_efforts: [Object.new, Object.new, Object.new],
      deleted_efforts: [Object.new],
    )
  end

  before do
    allow(Interactors::SyncRunsignupParticipants).to receive(:perform!).and_return(successful_response)
  end

  it "transitions the ImportJob through loading and into finished" do
    run!
    expect(import_job.reload).to be_finished
  end

  it "records counts on the ImportJob" do
    run!
    import_job.reload
    expect(import_job.row_count).to eq(7) # 2 created + 1 updated + 3 ignored + 1 deleted
    expect(import_job.succeeded_count).to eq(4) # created + updated + deleted
    expect(import_job.ignored_count).to eq(3)
    expect(import_job.failed_count).to eq(0)
  end

  it "sets started_at and elapsed_time" do
    run!
    import_job.reload
    expect(import_job.started_at).to be_present
    expect(import_job.elapsed_time).to be >= 0
  end

  context "when the interactor returns errors" do
    let(:unsuccessful_response) do
      Interactors::Response.new(
        [{ title: "boom", detail: { messages: ["nope"] } }],
        "Sync completed with errors",
        created_efforts: [],
        updated_efforts: [],
        ignored_efforts: [],
        deleted_efforts: [],
      )
    end

    before { allow(Interactors::SyncRunsignupParticipants).to receive(:perform!).and_return(unsuccessful_response) }

    it "marks the ImportJob failed and persists the error_message" do
      run!
      import_job.reload
      expect(import_job).to be_failed
      expect(JSON.parse(import_job.error_message).first["title"]).to eq("boom")
    end
  end

  context "when the interactor raises" do
    before { allow(Interactors::SyncRunsignupParticipants).to receive(:perform!).and_raise(RuntimeError, "kaboom") }

    it "marks the ImportJob failed, persists the error, and re-raises" do
      expect { run! }.to raise_error(RuntimeError, "kaboom")
      import_job.reload
      expect(import_job).to be_failed
      expect(import_job.error_message).to include("kaboom")
    end
  end

  context "when the format does not map to a syncing interactor" do
    let(:import_job) do
      ImportJob.new(parent: event, user: user, format: "lottery_entrants", status: :waiting).tap do |j|
        j.save!(validate: false)
      end
    end

    it "raises UnknownServiceError" do
      expect { run! }.to raise_error(SyncEntrantsRunner::UnknownServiceError)
    end
  end
end
