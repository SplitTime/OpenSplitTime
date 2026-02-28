require "rails_helper"

RSpec.describe "Setup summary entrants pagination", type: :system do
  let(:user) { create(:admin) }

  let(:event_group) { create(:event_group) }
  let(:event) { create(:event, event_group: event_group) }

  before do
    # Create > 50 entrants so pagination is needed (BasePresenter::DEFAULT_PER_PAGE = 50)
    create_list(:effort, 55, :with_bib_number, event: event)

    login_as user, scope: :user
  end

  it "includes a lazy-loading turbo frame for the next page of entrants" do
    visit setup_summary_event_group_path(event_group)

    # First page renders some entrants
    expect(page).to have_css("tbody#entrants tr")

    # And includes a lazy-loading turbo frame to fetch additional pages
    expect(page).to have_css("turbo-frame[id^='entrants_page_'][loading='lazy']")
  end
end
