# frozen_string_literal: true

require "rails_helper"

RSpec.describe "visit a lottery draws page" do
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

  context "when the lottery is in preview status" do
    before { lottery.update(status: :preview) }

    scenario "The user is an admin" do
      login_as admin, scope: :user

      visit_page
      verify_all_content_present
    end

    scenario "The user is the owner of the organization" do
      login_as owner, scope: :user

      visit_page
      verify_all_content_present
    end

    scenario "The user is a lottery manager of the organization" do
      stewardship = Stewardship.find_by(user: steward, organization: organization)
      stewardship.update(level: :lottery_manager)

      login_as steward, scope: :user

      visit_page
      verify_all_content_present
    end

    scenario "The user is a steward who is not a lottery manager of the organization" do
      login_as steward, scope: :user

      visit_page
      expect(page).to have_content("This lottery is not yet live")
    end

    scenario "The user is a visitor" do
      visit_page
      expect(page).to have_content("This lottery is not yet live")
    end
  end

  [:live, :finished].each do |status|
    context "when the lottery is in #{status} status" do
      before { lottery.update(status: status) }

      scenario "The user is an admin" do
        login_as admin, scope: :user

        visit_page
        verify_all_content_present
      end

      scenario "The user is the owner of the organization" do
        login_as owner, scope: :user

        visit_page
        verify_all_content_present
      end

      scenario "The user is a lottery manager of the organization" do
        stewardship = Stewardship.find_by(user: steward, organization: organization)
        stewardship.update(level: :lottery_manager)

        login_as steward, scope: :user

        visit_page
        verify_all_content_present
      end

      scenario "The user is a steward who is not a lottery manager of the organization" do
        login_as steward, scope: :user

        visit_page
        verify_public_content_present
        verify_admin_links_absent
      end

      scenario "The user is a visitor" do
        visit_page
        verify_public_content_present
        verify_admin_links_absent
      end
    end
  end

  def visit_page
    visit organization_lottery_path(organization, lottery, display_style: :draws)
  end

  def verify_all_content_present
    verify_public_content_present
    verify_admin_links_present
  end

  def verify_public_content_present
    lottery.entrants.drawn.each { |entrant| verify_content_present(entrant, :full_name) }
    lottery.entrants.undrawn.each { |entrant| verify_content_absent(entrant, :full_name) }

    verify_live_links_present
  end

  def verify_admin_links_present
    expect(page).to have_link("Admin", href: setup_organization_lottery_path(organization, lottery))
  end

  def verify_admin_links_absent
    expect(page).not_to have_link("Admin", href: setup_organization_lottery_path(organization, lottery))
  end

  def verify_live_links_present
    expect(page).to have_link("Browse Entrants and Results", href: organization_lottery_path(organization, lottery, display_style: :entrants))
  end
end
