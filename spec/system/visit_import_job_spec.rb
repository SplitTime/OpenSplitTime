require "rails_helper"

RSpec.describe "visit an import job spec page" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:other_user) { users(:fifth_user) }
  let(:parent_resource) { lotteries(:lottery_without_tickets) }
  let!(:import_job) { create(:import_job, user: test_user, parent_type: parent_resource.class.to_s, parent_id: parent_resource.id) }
  let!(:other_user_import_job) { create(:import_job, user: other_user, parent_type: parent_resource.class.to_s, parent_id: parent_resource.id) }
  let(:test_user) { user }

  context "For a logged-in user" do
    shared_examples "show page has expected content" do
      scenario "visit the import job page and see job for existing parent" do
        login_as test_user, scope: :user

        visit_page
        expect(page).to have_content("Import Job #{import_job.id}")
        expect(page).to have_content(test_user.full_name)
        expect(page).to have_link(parent_resource.name, href: setup_organization_lottery_path(parent_resource.organization, parent_resource))

        expect(page).not_to have_link(other_user_import_job.id.to_s, href: import_job_path(other_user_import_job))
      end

      scenario "visit the import job show page and see content for deleted parent" do
        login_as test_user, scope: :user
        parent_resource.destroy!

        visit_page
        expect(page).to have_content("Import Job #{import_job.id}")
        expect(page).to have_content(test_user.full_name)
        expect(page).to have_content("Resource not found")

        expect(page).not_to have_link(other_user_import_job.id.to_s, href: import_job_path(other_user_import_job))
      end
    end

    context "The user is an admin" do
      let(:test_user) { admin }
      include_examples "show page has expected content"
    end

    context "The user is a non-admin" do
      let(:test_user) { user }
      include_examples "show page has expected content"
    end

    context "The user is logged in but does not own the import job" do
      let(:test_user) { other_user }

      scenario "visit the import job show page" do
        visit_page
        expect(page).to have_current_path(root_path)
      end
    end
  end

  scenario "The user is a visitor" do
    visit_page
    expect(page).to have_current_path(root_path)
  end

  def visit_page
    visit import_job_path(import_job)
  end
end
