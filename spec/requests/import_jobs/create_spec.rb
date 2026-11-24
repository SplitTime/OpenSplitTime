require "rails_helper"

RSpec.describe "Import jobs create" do
  include Warden::Test::Helpers

  let(:admin_user) { users(:admin_user) }
  let(:event_group) { event_groups(:sum) }
  let(:import_job_params) do
    { format: :event_group_entrants, parent_type: "EventGroup", parent_id: event_group.id }
  end

  before { login_as admin_user, scope: :user }

  describe "POST create" do
    context "when a file is attached" do
      it "creates the import job" do
        file = fixture_file_upload("test_efforts_utf_8.csv", "text/csv")

        expect do
          post import_jobs_path, params: { import_job: import_job_params.merge(files: file) }
        end.to change(ImportJob, :count).by(1)
        expect(response).to redirect_to(import_jobs_path)
      end
    end

    context "when no file is attached" do
      it "does not create an import job and explains why" do
        expect do
          post import_jobs_path, params: { import_job: import_job_params }
        end.not_to change(ImportJob, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("No file was uploaded")
      end
    end
  end
end
