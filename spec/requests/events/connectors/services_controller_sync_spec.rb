require "rails_helper"

RSpec.describe "POST /events/:event_id/connector_services/:service_identifier/sync" do
  include ActiveJob::TestHelper
  include Warden::Test::Helpers

  let(:user) { users(:admin_user) }
  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:event) { events(:rufa_2017_24h) }

  before do
    login_as user, scope: :user
    # Avoid hitting Runsignup's real API while rendering the sync_efforts_card
    # — the presenter is instantiated inside the controller-rendered view so
    # per-instance stubbing isn't practical. The post-sync render only needs
    # the ImportJob status to assemble the card; real source data is irrelevant.
    allow_any_instance_of(ConnectServicePresenter).to receive(:all_sources).and_return([]) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ConnectServicePresenter).to receive(:sources_available?).and_return(true) # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(ConnectServicePresenter).to receive(:successful_connection?).and_return(true) # rubocop:disable RSpec/AnyInstance
  end

  after { Warden.test_reset! }

  it "creates an ImportJob in :waiting status with the service identifier as format" do
    expect { post sync_event_connector_service_path(event, "runsignup"), headers: turbo_headers }
      .to change(ImportJob, :count).by(1)

    job = ImportJob.last
    expect(job.parent).to eq(event)
    expect(job.user).to eq(user)
    expect(job.format).to eq("runsignup")
    expect(job).to be_waiting
  end

  it "enqueues a SyncEntrantsJob carrying the new ImportJob's id" do
    expect { post sync_event_connector_service_path(event, "runsignup"), headers: turbo_headers }
      .to have_enqueued_job(SyncEntrantsJob).with(an_instance_of(Integer))
  end

  it "renders the sync_entrants turbo_stream with the new ImportJob in the card" do
    post sync_event_connector_service_path(event, "runsignup"), headers: turbo_headers

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("Sync waiting")
  end
end
