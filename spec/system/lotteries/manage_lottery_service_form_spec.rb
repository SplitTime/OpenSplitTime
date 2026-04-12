require "rails_helper"

RSpec.describe "manage lottery service form upload and download", :js do
  let(:steward) { users(:third_user) }

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  before do
    lottery.update(status: :finished)
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  context "when service form not yet uploaded" do
    scenario "user uploads a service form" do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)
      expect(page).to have_text("Drag here to upload")

      attach_file_and_validate
      expect(page).to have_link("Download")
      expect(page).to have_button("Remove")
    end
  end

  context "when service form is available" do
    before do
      lottery.service_form.attach(
        io: File.open(file_fixture("service_form.pdf")),
        filename: "service_form.pdf",
        content_type: "application/pdf"
      )
    end

    scenario "user sees a link to download the service form" do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)
      expect(page).to have_link("Download", href: download_service_form_organization_lottery_path(organization, lottery))
    end

    scenario "user removes the service form" do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)

      click_button "Remove"
      expect(page).to have_current_path(page_path)
      expect(page).not_to have_link("Download")
      expect(page).not_to have_button("Remove")
    end
  end

  def visit_page
    visit page_path
  end

  def page_path
    setup_organization_lottery_path(organization, lottery)
  end

  def attach_file_and_validate
    upload_to_dropzone("service_form.pdf")
    click_button "Attach"
    expect(page).to have_link("Download")
    expect(lottery.reload.service_form.attached?).to eq(true)
  end
end
