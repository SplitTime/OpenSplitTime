# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User forgot password" do
  scenario "without email" do
    visit_page
    click_button "Send me reset password instructions"

    expect(page).to have_content("Email can't be blank")
  end

  scenario "with email" do
    user = users(:third_user)

    visit_page
    fill_in "Email", with: user.email
    click_button "Send me reset password instructions"

    expect(page).to have_content I18n.t("devise.passwords.send_instructions")
  end

  scenario "sign up" do
    visit_page
    click_link I18n.t("devise.shared.links.sign_up")

    expect(page).to have_current_path(new_user_registration_path)
  end

  scenario "didn't receive confirmation instructions" do
    visit_page
    click_link I18n.t("devise.shared.links.didn_t_receive_confirmation_instructions")

    expect(page).to have_current_path(new_user_confirmation_path)
  end

  def visit_page
    visit new_user_password_path
  end
end
