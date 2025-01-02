require "rails_helper"

RSpec.describe "Import entrants from the event group setup view", type: :system, js: true do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  scenario "the user is a visitor" do
    visit_page

    expect(page).to have_current_path(root_path)
    verify_alert("You need to sign in or sign up before continuing")
  end

  scenario "the user is not an owner or steward" do
    login_as user, scope: :user
    visit_page

    expect(page).to have_current_path(root_path)
    verify_alert("Access denied")
  end

  scenario "the user is a steward" do
    login_as steward, scope: :user
    visit_page

    expect(page).to have_current_path(root_path)
    verify_alert("Access denied")
  end

  scenario "the user is the organization owner" do
    login_as owner, scope: :user
    visit_page

    validate_import_job_created
  end

  scenario "the user is an admin" do
    login_as admin, scope: :user
    visit_page

    validate_import_job_created
  end

  private

  def visit_page
    params = {
      import_job: {
        format: :event_group_entrants,
        parent_type: "EventGroup",
        parent_id: event_group.id,
      }
    }

    visit new_import_job_path(params)
  end

  def validate_import_job_created
    find(".dropzone").drop(file_fixture("test_efforts_utf_8.csv"))
    expect do
      click_button "Import"
      sleep 1
    end.to change(ImportJob, :count).by(1)
    expect(current_path).to eq(import_jobs_path)
  end
end
