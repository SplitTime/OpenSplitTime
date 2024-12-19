# frozen_string_literal: true

require "rails_helper"

RSpec.describe "manage entrant service form upload and download", js: true do
  let(:user) { users(:fourth_user) }

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:entrant) { lottery_entrants(:lottery_entrant_0004) }
  let(:download_path) { Rails.root.join("tmp/downloads") }

  before do
    entrant.update!(email: user.email)
    lottery.update(status: :finished)
  end

  context "service form not available" do
    scenario "user visits the page" do
      login_as user, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)
      expect(page).to have_text("not yet available for download")
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
      login_as user, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)
      expect(page).to have_text("Download a blank service form")

      click_link "Download"
      downloaded_file = download_path.join("service_form.pdf")

      expect(File.exist?(downloaded_file)).to be true
      expect(page).to have_current_path(page_path)
    end

    scenario "user uploads a completed service form pdf" do
      login_as user, scope: :user
      visit_page

      expect(page).to have_current_path(page_path)
      attach_file_and_validate
      expect(page).to have_current_path(page_path)
      expect(page).to have_text("Under review")
    end

    context "completed form is attached and has been rejected" do
      before do
        entrant.create_service_detail
        entrant.service_detail.completed_form.attach(
          io: File.open(file_fixture("potato3.jpg")),
          filename: "potato3.jpg",
          content_type: "image/jpeg"
        )
      end

      context "and has been accepted" do
        before { entrant.service_detail.update(form_accepted_at: Time.zone.now, form_accepted_comments: "Thank you for your service") }

        scenario "user sees feedback" do
          login_as user, scope: :user
          visit_page

          expect(page).to have_current_path(page_path)
          expect(page).to have_text "Accepted"
          expect(page).to have_text "Thank you for your service"
        end
      end

      context "and has been rejected" do
        before { entrant.service_detail.update(form_rejected_at: Time.zone.now, form_rejected_comments: "This is a potato") }

        scenario "user sees feedback and removes the form" do
          login_as user, scope: :user
          visit_page

          expect(page).to have_current_path(page_path)
          expect(page).to have_text "Rejected"
          expect(page).to have_text "This is a potato"

          click_button "Remove"
          expect(page).to have_current_path(page_path)
          expect(page).to have_text "Not received"
          expect(page).not_to have_text "This is a potato"
        end
      end
    end
  end

  def visit_page
    visit page_path
  end

  def page_path
    organization_lottery_entrant_service_detail_path(organization, lottery, entrant)
  end

  def attach_file_and_validate
    find(".dropzone").drop(file_fixture("potato3.jpg"))
    click_button "Attach"
    sleep 1
    expect(entrant.service_detail.completed_form.attached?).to eq(true)
  end
end
