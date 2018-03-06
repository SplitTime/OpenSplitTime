require 'rails_helper'
include FeatureMacros

# These tests will fail if the test database is rebuilt using db:schema:load
# To fix, run db:structure:load on the new database. If tests still fail,
# run the following directly on the new database:

# CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text LANGUAGE SQL IMMUTABLE STRICT AS $function$
#   SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
# $function$;

RSpec.describe 'Visit the best efforts page and search for an effort' do
  before(:context) do
    create_hardrock_event
  end

  after(:context) do
    clean_up_database
  end

  let(:user) { create(:user) }
  let(:admin) { create(:admin) }
  let(:course) { Course.first }
  let(:effort_1) { Effort.first }
  let(:other_efforts) { Effort.where.not(id: effort_1.id) }

  scenario 'Visitor visits the page and searches for a name' do
    visit best_efforts_course_path(course)

    expect(page).to have_content(course.name)
    Effort.all.each do |effort|
      expect(page).to have_content(effort.full_name)
    end

    fill_in 'First name, last name, state, or country', with: effort_1.name
    click_button 'Find someone'
    wait_for_css

    expect(page).to have_content(effort_1.name)
    other_efforts.each do |effort|
      expect(page).not_to have_content(effort.name)
    end
  end
end
