# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User requests resend confirmation instructions" do
  scenario "without email" do
    visit_page
    click_button "Resend confirmation instructions"

    expect(page).to have_content("Email can't be blank")
  end

  scenario "with email" do
    user = users(:third_user)
    user.update(confirmed_at: nil)

    visit_page
    fill_in "Email", with: user.email
    click_button "Resend confirmation instructions"

    expect(page).to have_content("You will soon receive an email with instructions about how to confirm your account.")
  end

  scenario "sign up" do
    visit_page
    click_link I18n.t("devise.shared.links.sign_up")

    expect(page).to have_current_path(new_user_registration_path)
  end

  scenario "forgot password" do
    visit_page
    click_link I18n.t("devise.shared.links.forgot_your_password")

    expect(page).to have_current_path(new_user_password_path)
  end

  def visit_page
    visit new_user_confirmation_path
  end
end
