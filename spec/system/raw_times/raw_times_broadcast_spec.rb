require "rails_helper"

RSpec.describe "raw times broadcasting", :js do
  include ActionView::RecordIdentifier

  let(:steward) { users(:fifth_user) }
  let(:event_group) { event_groups(:sum) }
  let(:organization) { event_group.organization }
  let(:effort) { efforts(:sum_100k_drop_anvil) }
  let(:split) { splits(:sum_100k_course_rolling_pass_aid2) }
  let(:raw_time) do
    create(:raw_time,
           event_group: event_group,
           bib_number: effort.bib_number,
           split_name: split.base_name,
           entered_time: "09:10:00")
  end

  before do
    organization.stewards << steward
  end

  scenario "updates are broadcast to other connected clients" do
    # Visit the page in two sessions
    using_session :session1 do
      login_as steward, scope: :user
      visit raw_times_event_group_path(event_group)
      expect(page).to have_css("##{dom_id(raw_time)}")
    end

    using_session :session2 do
      login_as steward, scope: :user
      visit raw_times_event_group_path(event_group)
      expect(page).to have_css("##{dom_id(raw_time)}")

      # Verify raw time is not reviewed
      within("##{dom_id(raw_time)}") do
        expect(page).to have_content("--", wait: 5)
        expect(page).not_to have_css(".fa-check")
      end
    end

    # Update raw time in session 1
    using_session :session1 do
      within("##{dom_id(raw_time)}") do
        button = find("#set-reviewed-raw-time-#{raw_time.id}")
        button.click
        # Wait for the button to change
        expect(page).to have_css("#set-unreviewed-raw-time-#{raw_time.id}", wait: 5)
      end
    end

    # Check that session 2 receives the update
    using_session :session2 do
      within("##{dom_id(raw_time)}") do
        # Should see the reviewer name and reviewed icon without refreshing
        expect(page).to have_content(steward.full_name, wait: 5)
        expect(page).to have_css(".fa-check")
      end
    end
  end

  scenario "new raw times are broadcast to all connected clients" do
    using_session :session1 do
      login_as steward, scope: :user
      visit raw_times_event_group_path(event_group)
    end

    using_session :session2 do
      login_as steward, scope: :user
      visit raw_times_event_group_path(event_group)
    end

    # Create a new raw time programmatically (simulating API creation)
    new_raw_time = nil
    using_session :session1 do
      expect do
        new_raw_time = create(:raw_time,
                              event_group: event_group,
                              bib_number: "999",
                              split_name: split.base_name,
                              entered_time: "10:00:00")
      end.to change { page.all("tbody tr").count }.by(1)
    end

    # Check that session 2 also sees the new raw time
    using_session :session2 do
      expect(page).to have_css("##{dom_id(new_raw_time)}", wait: 5)
      within("##{dom_id(new_raw_time)}") do
        expect(page).to have_content("999")
        expect(page).to have_content("10:00:00")
      end
    end
  end
end
