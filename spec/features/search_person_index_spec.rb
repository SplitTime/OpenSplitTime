require 'rails_helper'

# These tests will fail if the test database is rebuilt using db:schema:load
# To fix, run the following directly on the new database:

# CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text LANGUAGE SQL IMMUTABLE STRICT AS $function$
#   SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
# $function$;

RSpec.feature 'Search the person index' do
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let!(:visible_person_1) { create(:person, concealed: false) }
  let!(:visible_person_2) { create(:person, concealed: false) }
  let!(:concealed_person) { create(:person, concealed: true) }

  scenario 'The user is a visitor searching for a visible person' do
    visit people_path
    fill_in 'First name, last name, state, or country', with: visible_person_1.name
    click_button 'Find someone'

    expect(page).to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a visitor searching for a concealed person' do
    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'Find someone'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a visible person' do
    login_as user, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: visible_person_1.name
    click_button 'Find someone'

    expect(page).to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a concealed person that is not visible to the user' do
    login_as user, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'Find someone'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).not_to have_content(concealed_person.name)
  end

  scenario 'The user is a user searching for a concealed person that is visible to the user' do
    login_as admin, scope: :user

    visit people_path
    fill_in 'First name, last name, state, or country', with: concealed_person.name
    click_button 'Find someone'

    expect(page).not_to have_content(visible_person_1.name)
    expect(page).not_to have_content(visible_person_2.name)
    expect(page).to have_content(concealed_person.name)
  end
end
