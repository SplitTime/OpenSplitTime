# frozen_string_literal: true

require "rails_helper"

RSpec.describe "manage partners for an event group" do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }

  before do
    organization.stewards << steward
  end

  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }

  scenario "The user adds a partner" do
    login_as steward, scope: :user
    visit_page

    click_link "Add a partner"
    expect(page).to have_current_path(new_organization_event_group_partner_path(organization, event_group))

    fill_in "Name", with: "Example Partner"
    fill_in "Banner link", with: "https://www.example.com"
    attach_file("partner[banner]", file_fixture("banner.png"))

    expect do
      click_button "Create Partner"
      expect(page).to have_current_path(organization_event_group_partners_path(organization, event_group))
    end.to change { event_group.partners.count }.by(1)

    expect(page).to have_content("Example Partner")
    expect(page).to have_link(href: "https://www.example.com")
  end

  scenario "The user edits a partner" do
    partner = FactoryBot.create(:partner, :with_banner, partnerable: event_group, name: "Example Partner")
    login_as steward, scope: :user
    visit_page

    within("##{dom_id(partner)}") { click_link(href: edit_organization_event_group_partner_path(organization, event_group, partner)) }
    expect(page).to have_current_path(edit_organization_event_group_partner_path(organization, event_group, partner))

    fill_in "Name", with: "Example Partner Updated"
    click_button "Update Partner"

    expect(page).to have_current_path(organization_event_group_partners_path(organization, event_group))
    expect(page).to have_content("Example Partner Updated")
  end

  scenario "The user deletes a partner" do
    partner = FactoryBot.create(:partner, :with_banner, partnerable: event_group, name: "Example Partner")
    login_as steward, scope: :user
    visit_page

    expect do
      within("##{dom_id(partner)}") { click_link(href: organization_event_group_partner_path(organization, event_group, partner)) }
      expect(page).to have_current_path(organization_event_group_partners_path(organization, event_group))
    end.to change { event_group.partners.count }.by(-1)
  end

  def visit_page
    visit organization_event_group_partners_path(organization, event_group)
  end
end
