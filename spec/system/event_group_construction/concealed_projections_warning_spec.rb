require "rails_helper"

RSpec.describe "warnings when a concealed event group feeds projections", :js, type: :system do
  let(:admin) { users(:admin_user) }
  let(:event_group) { event_groups(:sum) }
  let(:event) { event_group.events.first }

  before { login_as admin, scope: :user }

  describe "the event group setup page" do
    context "when the event group is concealed and its events feed projections" do
      before { event_group.update_column(:concealed, true) }

      scenario "shows the warning with links to the events" do
        visit setup_event_group_path(event_group)

        expect(page).to have_content("This private group's times feed projections")
        expect(page).to have_link(event.guaranteed_short_name, href: edit_event_group_event_path(event_group, event))
      end
    end

    context "when the event group is visible" do
      scenario "does not show the warning" do
        visit setup_event_group_path(event_group)

        expect(page).to have_content(event_group.name)
        expect(page).not_to have_content("This private group's times feed projections")
      end
    end

    context "when the event group is concealed but no events feed projections" do
      before do
        event_group.update_column(:concealed, true)
        event_group.events.each { |e| e.update_column(:use_for_projections, false) }
      end

      scenario "does not show the warning" do
        visit setup_event_group_path(event_group)

        expect(page).to have_content(event_group.name)
        expect(page).not_to have_content("This private group's times feed projections")
      end
    end
  end

  describe "the setup summary page" do
    context "when the event group is concealed and its events feed projections" do
      before { event_group.update_column(:concealed, true) }

      scenario "shows the warning" do
        visit setup_summary_event_group_path(event_group)

        expect(page).to have_content("This private group's times feed projections")
      end
    end
  end

  describe "the edit event page" do
    context "when the event group is concealed" do
      before { event_group.update_column(:concealed, true) }

      scenario "shows the inline projections warning" do
        visit edit_event_group_event_path(event_group, event)

        expect(page).to have_content("This Event Group is private, but this Event's times will still feed")
      end
    end

    context "when the event group is visible" do
      scenario "does not show the inline projections warning" do
        visit edit_event_group_event_path(event_group, event)

        expect(page).to have_content("Use this event's times for projections")
        expect(page).not_to have_content("this Event's times will still feed")
      end
    end
  end
end
