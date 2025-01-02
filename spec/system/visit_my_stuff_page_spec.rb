require "rails_helper"

RSpec.describe "Visit the My Stuff page" do
  let(:non_admin) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:organization_1) { organizations(:hardrock) }
  let(:organization_2) { organizations(:rattlesnake_ramble) }

  scenario "The user is a non-admin user" do
    login_as non_admin, scope: :user
    visit_my_stuff_path

    verify_headings_present
  end

  scenario "The user is an admin user" do
    login_as admin, scope: :user
    visit_my_stuff_path

    verify_headings_present
  end

  def visit_my_stuff_path
    visit my_stuff_path
  end

  def verify_headings_present
    expect(page).to have_content("My Events")
    expect(page).to have_content("My Organizations")
  end
end
