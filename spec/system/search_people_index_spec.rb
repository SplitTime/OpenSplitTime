# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit and search the people index' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  let(:concealed_person_1) { people(:drop_ouray) }
  let(:concealed_person_2) { people(:progress_rolling) }
  let(:concealed_californians) { [concealed_person_1, concealed_person_2] }
  let(:visible_californians) { people.select { |person| person.state_code == 'CA' } - concealed_californians }
  let(:non_californians) { people - concealed_californians - visible_californians }

  before do
    concealed_californians.each { |person| person.update(concealed: true) }
  end

  scenario 'The user is a visitor' do
    visit people_path
    verify_public_content_present

    fill_in 'First name, last name, state, or country', with: 'California'
    click_button 'person-lookup-submit'

    verify_visible_matching_present
    verify_concealed_matching_absent
    verify_non_matching_absent
  end

  scenario 'The user is a non-admin user' do
    login_as user, scope: :user
    visit people_path
    verify_public_content_present

    fill_in 'First name, last name, state, or country', with: 'California'
    click_button 'person-lookup-submit'

    verify_visible_matching_present
    verify_concealed_matching_absent
    verify_non_matching_absent
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit people_path
    verify_public_content_present

    fill_in 'First name, last name, state, or country', with: 'California'
    click_button 'person-lookup-submit'

    verify_visible_matching_present
    verify_concealed_matching_present
    verify_non_matching_absent
  end

  context 'when searching for a specific person' do
    let(:visible_person_1) { visible_californians.first }
    let(:visible_person_2) { visible_californians.second }

    scenario 'The user is a visitor searching for a visible person' do
      visit people_path
      fill_in 'First name, last name, state, or country', with: visible_person_1.name
      click_button 'person-lookup-submit'

      verify_link_present(visible_person_1)
      verify_content_absent(visible_person_2)
      verify_content_absent(concealed_person_1)
      verify_content_absent(concealed_person_2)
    end

    scenario 'The user is a visitor searching for a concealed person' do
      visit people_path
      fill_in 'First name, last name, state, or country', with: concealed_person_1.name
      click_button 'person-lookup-submit'

      verify_content_absent(visible_person_1)
      verify_content_absent(visible_person_2)
      verify_content_absent(concealed_person_1)
      verify_content_absent(concealed_person_2)
    end

    scenario 'The user is a user searching for a visible person' do
      login_as user, scope: :user

      visit people_path
      fill_in 'First name, last name, state, or country', with: visible_person_1.name
      click_button 'person-lookup-submit'

      verify_link_present(visible_person_1)
      verify_content_absent(visible_person_2)
      verify_content_absent(concealed_person_1)
      verify_content_absent(concealed_person_2)
    end

    scenario 'The user is a user searching for a concealed person that is not visible to the user' do
      login_as user, scope: :user

      visit people_path
      fill_in 'First name, last name, state, or country', with: concealed_person_1.name
      click_button 'person-lookup-submit'

      verify_content_absent(visible_person_1)
      verify_content_absent(visible_person_2)
      verify_content_absent(concealed_person_1)
      verify_content_absent(concealed_person_2)
    end

    scenario 'The user is an admin' do
      login_as admin, scope: :user

      visit people_path
      fill_in 'First name, last name, state, or country', with: concealed_person_1.name
      click_button 'person-lookup-submit'

      verify_content_absent(visible_person_1)
      verify_content_absent(visible_person_2)
      verify_link_present(concealed_person_1)
      verify_content_absent(concealed_person_2)
    end
  end

  def verify_public_content_present
    expect(page).to have_content('People')
    expect(page).to have_content('Find someone by entering a name, state, or country')
  end

  def verify_visible_matching_present
    visible_californians.each { |person| verify_link_present(person, :full_name) }
  end

  def verify_concealed_matching_present
    concealed_californians.each { |person| verify_link_present(person, :full_name) }
  end

  def verify_concealed_matching_absent
    concealed_californians.each { |person| verify_content_absent(person, :full_name) }
  end

  def verify_non_matching_absent
    non_californians.each { |person| verify_content_absent(person, :full_name) }
  end
end
