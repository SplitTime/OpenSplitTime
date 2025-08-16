require "rails_helper"

RSpec.describe "Import event efforts with military times", type: :system, js: true do
  let(:owner) { users(:fourth_user) }

  before do
    organization.update(created_by: owner.id)
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:event) { events(:sum_55k) }

  scenario "The user imports efforts" do
    login_as owner, scope: :user
    visit_page

    validate_import_job_created
  end

  private

  def visit_page
    params = {
      import_job: {
        format: :event_entrants_with_military_times,
        parent_type: "Event",
        parent_id: event.id,
      }
    }

    visit new_import_job_path(params)
  end

  def validate_import_job_created
    expect do
      upload_to_dropzone("test_efforts_utf_8.csv")
      click_button "Import"
    end.to change(ImportJob, :count).by(1)

    expect(current_path).to eq(import_jobs_path)
  end
end
