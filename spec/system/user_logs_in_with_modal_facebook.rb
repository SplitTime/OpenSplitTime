# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User logs in with modal", js: true do
  let(:user) { users(:admin_user) }

  scenario "with facebook oauth" do
    visit organizations_path
    
    login_with_facebook
    verify_valid
  end

  def login_with_facebook
    within(".navbar") do
      click_link "Log In"
    end
    
    within("#log-in-modal") do
      click_button "#facebook-log-in-button"
    end
  end

  def verify_valid
    expect(page).to have_content(user.email)
    expect(page).to have_current_path(organizations_path)
  end

  def verify_invalid
    expect(page).to have_content(:all, "Invalid email or password")
    expect(page).to have_current_path(organizations_path)
  end
end
