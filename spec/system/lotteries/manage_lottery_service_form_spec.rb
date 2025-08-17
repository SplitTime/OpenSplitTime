require "rails_helper"

RSpec.describe "manage lottery service form upload and download", js: true do
  let(:steward) { users(:third_user) }

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:download_path) { Rails.root.join("tmp/downloads") }

  before do
    lottery.update(status: :finished)
    organization.stewards << steward
    stewardship = organization.stewardships.find_by(user: steward)
    stewardship.update(level: :lottery_manager)
  end

  context "service form not yet uploaded" do
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

  context "service form is available" do
    before do
      lottery.service_form.attach(
        io: File.open(file_fixture("service_form.pdf")),
        filename: "service_form.pdf",
        content_type: "application/pdf"
      )
    end

    scenario "user downloads the service form", :local_only do
      login_as steward, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)

      click_link "Download"
      downloaded_file = download_path.join("service_form.pdf")

      expect(File.exist?(downloaded_file)).to be true
      expect(page).to have_current_path(page_path)
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
    expect(lottery.service_form.attached?).to eq(true)
  end
end
