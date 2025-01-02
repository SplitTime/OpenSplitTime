require "rails_helper"

RSpec.describe "visit the madmin root page" do
  let(:admin) { users(:admin_user) }
  let(:user) { users(:third_user) }

  scenario "The user is a visitor" do
    visit madmin_root_path
    expect(page).to have_current_path(root_path)
  end

  scenario "The user is a non-admin user" do
    login_as user, scope: :user

    visit madmin_root_path
    expect(page).to have_current_path(root_path)
  end

  scenario "The user is an admin" do
    login_as admin, scope: :user

    visit madmin_root_path
    expect(page).to have_current_path(madmin_root_path)
  end
end
