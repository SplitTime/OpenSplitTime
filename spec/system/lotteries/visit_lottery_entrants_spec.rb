# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit a lottery entrants page" do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:lottery) { lotteries(:lottery_with_tickets_and_draws) }
  let(:organization) { lottery.organization }
  let(:all_entrants) { lottery.entrants }
  let(:entrant_1) { lottery.entrants.find_by(first_name: "Maud", last_name: "Boyer") }
  let(:other_entrants) { all_entrants.where.not(id: entrant_1.id) }

  context "when the lottery is in preview status" do
    before { lottery.update(status: :preview) }

    scenario "The user is an admin" do
      login_as admin, scope: :user

      visit_page
      verify_all_links_present
      verify_ticket_link_preview_works
    end

    scenario "The user is the owner of the organization" do
      login_as owner, scope: :user

      visit_page
      verify_all_links_present
      verify_ticket_link_preview_works
    end

    scenario "The user is a lottery manager of the organization" do
      stewardship = Stewardship.find_by(user: steward, organization: organization)
      stewardship.update(level: :lottery_manager)

      login_as steward, scope: :user

      visit_page
      verify_all_links_present
      verify_ticket_link_preview_works
    end

    scenario "The user is a steward who is not a lottery manager of the organization" do
      login_as steward, scope: :user

      visit_page
      verify_public_names_present
      verify_public_links_present
      verify_live_links_absent
      verify_admin_links_absent
      verify_ticket_link_preview_works
    end

    scenario "The user is a visitor" do
      visit_page
      verify_public_names_present
      verify_public_links_present
      verify_live_links_absent
      verify_admin_links_absent
      verify_ticket_link_preview_works
    end
  end

  [:live, :finished].each do |status|
    context "when the lottery is in #{status} status" do
      before { lottery.update(status: status) }

      scenario "The user is an admin" do
        login_as admin, scope: :user

        visit_page
        verify_all_links_present
        verify_ticket_link_works
      end

      scenario "The user is the owner of the organization" do
        login_as owner, scope: :user

        visit_page
        verify_all_links_present
        verify_ticket_link_works
      end

      scenario "The user is a lottery manager of the organization" do
        stewardship = Stewardship.find_by(user: steward, organization: organization)
        stewardship.update(level: :lottery_manager)

        login_as steward, scope: :user

        visit_page
        verify_all_links_present
        verify_ticket_link_works
      end

      scenario "The user is a steward who is not a lottery manager of the organization" do
        login_as steward, scope: :user

        visit_page
        verify_public_names_present
        verify_public_links_present
        verify_live_links_present
        verify_admin_links_absent
        verify_ticket_link_works
      end

      scenario "The user is a visitor" do
        visit_page
        verify_public_names_present
        verify_public_links_present
        verify_live_links_present
        verify_admin_links_absent
        verify_ticket_link_works
      end
    end
  end

  scenario "The user searches for a name" do
    login_as admin, scope: :user

    visit_page

    fill_in "Find someone", with: entrant_1.full_name
    search_button.click

    verify_single_name_present
  end

  def visit_page
    visit organization_lottery_path(organization, lottery, display_style: :entrants)
  end

  def search_button
    find("#lottery-entrant-lookup-submit")
  end

  def verify_public_names_present
    verify_content_present(lottery)
    all_entrants.each { |entrant| verify_content_present(entrant, :full_name) }
  end

  def verify_all_links_present
    verify_public_names_present
    verify_public_links_present
    verify_live_links_present
    verify_admin_links_present
  end

  def verify_public_links_present
    expect(page).to have_link("Entrants", href: organization_lottery_path(organization, lottery, display_style: :entrants))
  end

  def verify_admin_links_present
    expect(page).to have_link("Admin", href: setup_organization_lottery_path(organization, lottery))
  end

  def verify_admin_links_absent
    expect(page).not_to have_link("Admin", href: setup_organization_lottery_path(organization, lottery))
  end

  def verify_live_links_present
    expect(page).to have_link("Results", href: organization_lottery_path(organization, lottery, display_style: :results))
    expect(page).to have_link("View Draws", href: organization_lottery_path(organization, lottery, display_style: :draws))
  end

  def verify_live_links_absent
    expect(page).not_to have_link("Results", href: organization_lottery_path(organization, lottery, display_style: :results))
    expect(page).not_to have_link("View Draws", href: organization_lottery_path(organization, lottery, display_style: :draws))
  end

  def verify_single_name_present
    verify_content_present(entrant_1, :full_name)
    other_entrants.each { |entrant| verify_content_absent(entrant, :full_name) }
  end

  def verify_ticket_link_preview_works
    entrant_id = 6
    entrant = ::LotteryEntrant.find(entrant_id)
    entrant_card = find("#lottery_entrant_#{entrant_id}")
    expect(entrant_card).to have_link("3 tickets")
    ticket_numbers = entrant.tickets.pluck(:reference_number)
    ticket_numbers.each { |ticket_number| expect(entrant_card).not_to have_content(ticket_number) }

    entrant_card.click_link("3 tickets")

    expect(entrant_card).to have_content("Tickets will appear here once the lottery is live")
  end

  def verify_ticket_link_works
    entrant_id = 6
    entrant = ::LotteryEntrant.find(entrant_id)
    entrant_card = find("#lottery_entrant_#{entrant_id}")
    expect(entrant_card).to have_link("3 tickets")
    ticket_numbers = entrant.tickets.pluck(:reference_number)
    ticket_numbers.each { |ticket_number| expect(entrant_card).not_to have_content(ticket_number) }

    entrant_card.click_link("3 tickets")

    ticket_numbers.each { |ticket_number| expect(entrant_card).to have_content(ticket_number) }
  end
end
