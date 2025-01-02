require "rails_helper"

RSpec.describe "User logs in with modal", type: :system, js: true do
  let(:user) { users(:admin_user) }
  let(:email) { user.email }
  let(:password) { "password" }

  let(:invalid_email) { "joe@example.com" }
  let(:invalid_password) { "11111111" }

  scenario "with valid email and password" do
    visit organizations_path

    login_with_modal(email, password)
    verify_valid
  end

  scenario "with invalid email" do
    visit organizations_path

    login_with_modal(invalid_email, password)
    verify_invalid
  end

  scenario "with invalid password" do
    visit organizations_path

    login_with_modal(email, invalid_password)
    verify_invalid
  end

  scenario "sign up" do
    visit organizations_path
    within(".navbar") { click_link "Log In" }
    within("#form_modal") { click_link I18n.t("devise.shared.links.sign_up") }

    expect(page).to have_current_path(new_user_registration_path)
  end

  scenario "forgot password" do
    visit organizations_path
    within(".navbar") { click_link "Log In" }
    within("#form_modal") { click_link I18n.t("devise.shared.links.forgot_your_password") }

    expect(page).to have_current_path(new_user_password_path)
  end

  scenario "didn't receive confirmation instructions" do
    visit organizations_path
    within(".navbar") { click_link "Log In" }
    within("#form_modal") { click_link I18n.t("devise.shared.links.didn_t_receive_confirmation_instructions") }

    expect(page).to have_current_path(new_user_confirmation_path)
  end

  def login_with_modal(email, password)
    click_login_link

    within("#form_modal") do
      fill_in "Email", with: email
      fill_in "Password", with: password
      click_button "Log in"
    end
  end

  def click_login_link
    within(".navbar") { click_link "Log In" }
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
