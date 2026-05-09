require "rails_helper"

RSpec.describe "Events#update_start_time" do
  include ActiveJob::TestHelper
  include Warden::Test::Helpers

  subject(:make_request) { patch update_start_time_event_path(event), params: params }

  let(:event) { events(:ramble) }
  let(:admin_user) { users(:admin_user) }
  let(:params) do
    {
      event: {
        scheduled_start_time_local: "2017-10-01 08:00:00"
      }
    }
  end

  before do
    login_as admin_user, scope: :user
  end

  after do
    clear_enqueued_jobs
    clear_performed_jobs
    Warden.test_reset!
  end

  it "enqueues EventUpdateStartTimeJob" do
    expect { make_request }.to have_enqueued_job(EventUpdateStartTimeJob)
      .with(event, new_start_time: "2017-10-01 08:00:00 -0600", current_user: admin_user)
  end

  it "redirects to setup with an in-progress notice" do
    make_request

    expect(response).to redirect_to(setup_event_group_path(event.event_group))
    expect(flash[:notice]).to eq("Shifting start time...")
  end
end
