require "rails_helper"

RSpec.describe "Infinite scroll pagination", type: :system do
  let(:user) { create(:admin) }

  before do
    login_as user, scope: :user
  end

  it "replaces event groups page-number pagination with Show More autoclick link" do
    create_list(:event_group, 30) # controller per_page is 25

    visit event_groups_path

    expect(page).to have_link("Show More", href: /page=2/)
    expect(page).not_to have_content("Previous")
    expect(page).not_to have_content("Next")
  end

  it "replaces users page-number pagination with Show More autoclick link" do
    create_list(:user, 30)

    visit users_path

    expect(page).to have_link("Show More", href: /page=2/)
    expect(page).not_to have_content("Previous")
    expect(page).not_to have_content("Next")
  end

  it "replaces people page-number pagination with Show More autoclick link" do
    event_group = create(:event_group)
    event = create(:event, event_group: event_group)

    people = create_list(:person, 30, :male, last_name: "Smith", concealed: false)
    people.each { |person| create(:effort, event: event, person: person) }

    visit people_path(filter: { search: "Smith" })

    expect(page).to have_content("Smith")
    expect(page).to have_link("Show More", href: /page=2/)
    expect(page).not_to have_content("Previous")
    expect(page).not_to have_content("Next")
  end
end
