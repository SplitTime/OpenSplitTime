# frozen_string_literal: true

require 'rails_helper'

# These tests will fail if the test database is rebuilt using db:schema:load
# To fix, run the following from the command line:

# rails db:structure:load RAILS_ENV=test

RSpec.describe 'Search the person index' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let!(:visible_person_1) { people.sort_by(&:last_name).first }
  let!(:visible_person_2) { people.sort_by(&:last_name).second }
  let!(:concealed_person) { people.sort_by(&:last_name).last }

  before { concealed_person.update(concealed: true) }

  scenario 'The user is a visitor searching for a visible person' do
    visit people_path
    fill_in 'First name, last name, state, or country', with: visible_person_1.name
    click_button 'person-lookup-submit'

    expect(page).to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a visitor searching for a concealed person' do
    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'person-lookup-submit'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a visible person' do
    login_as user, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: visible_person_1.name
    click_button 'person-lookup-submit'

    expect(page).to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a concealed person that is not visible to the user' do
    login_as user, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'person-lookup-submit'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a concealed person that is visible to the user' do
    login_as admin, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'person-lookup-submit'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).to have_content(concealed_person.name)
  end
end
