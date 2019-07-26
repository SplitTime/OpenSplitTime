# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the user index page' do
  let(:admin) { users(:admin_user) }
  let(:user) { users(:third_user) }
  let(:impersonation_text) { "#{admin.full_name} is impersonating #{user.full_name}" }

  scenario 'An admin views the users index page' do
    login_as admin, scope: :user

    visit users_path
    verify_all_users_listed
  end

  scenario 'An admin deletes a user' do
    login_as admin, scope: :user

    visit users_path
    verify_all_users_listed
    button = find_link(id: "delete_user_#{user.id}")
    button.click

    verify_content_absent(user, :full_name)
  end

  scenario 'An admin impersonates a user and then stops impersonating' do
    login_as admin, scope: :user

    visit users_path
    button = find_link(id: "impersonate_user_#{user.id}")
    button.click

    expect(current_path).to eq(root_path)
    expect(page).to have_content(impersonation_text)

    visit organizations_path
    click_link 'Stop impersonating'

    expect(current_path).to eq(organizations_path)
    expect(page).not_to have_content(impersonation_text)
    expect(page).not_to have_content(user.email)
    expect(page).to have_content(admin.email)
  end

  private

  def verify_all_users_listed
    User.all.each { |user| verify_link_present(user, :full_name) }
  end
end
