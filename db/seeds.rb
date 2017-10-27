# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

User.create!(first_name: 'Admin', last_name: 'User', role: :admin, email: 'user@example.com', password: 'password', confirmed_at: Time.now)
User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'tester@example.com', password: 'password', confirmed_at: Time.now)
third = User.create!(first_name: 'Third', last_name: 'User', role: :user, email: 'thirduser@example.com', password: 'password', confirmed_at: Time.now)
fourth = User.create!(first_name: 'Fourth', last_name: 'User', role: :user, email: 'fourthuser@example.com', password: 'password', confirmed_at: Time.now)

test_course = Course.create!(name: 'Test Course CCW')
another_course = Course.create!(name: 'Another Course')
hardrock_course = Course.create!(name: 'Hardrock CCW', description: 'Counter-clockwise Hardrock 100 course, starting in Silverton, going to Sherman, over Handies Peak, to Ouray, Telluride, and back to Silverton')

slo_mo_org = Organization.create!(name: 'Slo Mo 100')
frozen_lips_org = Organization.create!(name: 'Frozen Lips 100')
hardly_rocker_org = Organization.create!(name: 'Hardly Rocker 100')
hardrock_org = Organization.create!(name: 'Hardrock 100')

slo_mo_group = EventGroup.create!(name: 'Slo Mo Weekend', organization: slo_mo_org)
frozen_group = EventGroup.create!(name: 'Frozen Lips 100', organization: frozen_lips_org)
hardly_rocker_group = EventGroup.create!(name: 'Hardly Rocker 100', organization: hardly_rocker_org)
hardrock_group = EventGroup.create!(name: 'Hardrock 100', organization: hardrock_org)

hardly_rocker = Event.create!(course: another_course, event_group: hardly_rocker_group, name: 'Hardly Rocker 2010', start_time: "2010-08-10 06:00:00", home_time_zone: 'Arizona', laps_required: 1)
frozen_lips = Event.create!(course: another_course, event_group: frozen_group, name: 'Frozen Lips 2015', start_time: "2015-05-31 07:00:00", home_time_zone: 'Eastern Time (US & Canada)', laps_required: 1)
test_event = Event.create!(course: test_course, event_group: slo_mo_group, name: 'Test Event', start_time: "2012-08-08 05:00:00", home_time_zone: 'GMT', laps_required: 1)
Event.create!(course: hardrock_course, event_group: hardrock_group, name: 'Hardrock 100 2015', start_time: "2015-07-10 06:00:00", home_time_zone: 'Mountain Time (US & Canada)', laps_required: 1)

test_start = Split.create!(course: test_course, base_name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0, elevation: 2400, latitude: 40.1, longitude: -105)
test_aid_1 = Split.create!(course: test_course, base_name: 'Test Aid Station 1', distance_from_start: 4000, sub_split_bitmap: 65, vert_gain_from_start: 400, vert_loss_from_start: 0, kind: 2, elevation: 3000, latitude: 40.2, longitude: -105.4)
test_aid_2 = Split.create!(course: test_course, base_name: 'Test Aid Station 2', distance_from_start: 7000, sub_split_bitmap: 65, vert_gain_from_start: 700, vert_loss_from_start: 0, kind: 2, elevation: 3000, latitude: 40.2, longitude: -105.4)
test_finish = Split.create!(course: test_course, base_name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 1000, vert_loss_from_start: 1000, kind: 1, elevation: 2800, latitude: 40.05, longitude: -105.2)
Split.create!(course: another_course, base_name: 'Another Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0, elevation: 200, latitude: -43, longitude: 146.3)
Split.create!(course: another_course, base_name: 'Another Aid Station', distance_from_start: 6000, sub_split_bitmap: 65, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2, elevation: 250, latitude: -43.1, longitude: 146.4)
Split.create!(course: another_course, base_name: 'Another Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1, elevation: 300, latitude: -43.2, longitude: 146.2)

test_course.splits.each do |split|
  test_event.splits << split
end

joe = Person.create!(first_name: 'Joe', last_name: 'Hardman', gender: 'male', birthdate: "1989-12-15", city: 'Boulder', state_code: 'CO', country_code: 'US', email: 'hardman@gmail.com', phone: nil)
jane = Person.create!(first_name: 'Jane', last_name: 'Rockstar', gender: 'female', birthdate: "1985-09-20", city: 'Seattle', state_code: 'WA', country_code: 'US', email: nil, phone: '206-977-9777')
basil = Person.create!(first_name: 'Basil', last_name: 'Smith', gender: 'male', birthdate: "1995-04-31", city: 'Guildford', state_code: 'SRY', country_code: 'GB', email: 'basil@uk.gov')
jen = Person.create!(first_name: 'Jen', last_name: 'Huckster', gender: 'female', birthdate: nil, city: 'Vancouver', state_code: 'BC', country_code: 'CA', email: 'jane@canuck.com', phone: '804-888-5555')

jen_test = Effort.create!(event: test_event, person: jen, bib_number: 99, city: 'Vancouver', state_code: 'BC', country_code: 'CA', age: 50, start_time: "2012-08-08 05:00:00", first_name: 'Jen', last_name: 'Huckster', gender: 'female')
joe_test = Effort.create!(event: test_event, person: joe, bib_number: 12, city: 'Boulder', state_code: 'CO', country_code: 'US', age: 23, start_time: "2012-08-08 05:00:00", first_name: 'Joe', last_name: 'Hardman', gender: 'male')
Effort.create!(event: hardly_rocker, person: jane, bib_number: 1775, city: 'Atlanta', state_code: 'GA', country_code: 'US', age: 24, start_time: "2010-08-10 06:00:00", first_name: 'Jane', last_name: 'Rockstar', gender: 'female')
Effort.create!(event: frozen_lips, person: basil, bib_number: 44, city: 'Guildford', state_code: 'SRY', country_code: 'GB', age: 20, start_time: "2015-05-31 07:00:00", first_name: 'Basil', last_name: 'Smith', gender: 'male')
Effort.create!(event: hardly_rocker, person: basil, bib_number: 66, city: 'Cranleigh', state_code: 'SRY', country_code: 'GB', age: 15, start_time: "2010-08-10 06:00:00", first_name: 'Basil', last_name: 'Smith', gender: 'male')
jane_test = Effort.create!(event: test_event, person: jane, bib_number: 150, city: 'Nantucket', state_code: 'MA', country_code: 'US', age: 26, start_time: "2012-08-08 05:00:00", first_name: 'Jane', last_name: 'Rockstar', gender: 'female')

SplitTime.create!(effort: jen_test, split: test_start, lap: 1, bitkey: 1, time_from_start: 0)
SplitTime.create!(effort: jen_test, split: test_aid_1, lap: 1, bitkey: 1, time_from_start: 4000)
SplitTime.create!(effort: jen_test, split: test_aid_2, lap: 1, bitkey: 1, time_from_start: 4100)
SplitTime.create!(effort: jen_test, split: test_finish, lap: 1, bitkey: 1, time_from_start: 8000)
SplitTime.create!(effort: joe_test, split: test_start, lap: 1, bitkey: 1, time_from_start: 0)
SplitTime.create!(effort: joe_test, split: test_aid_1, lap: 1, bitkey: 1, time_from_start: 5000)
SplitTime.create!(effort: joe_test, split: test_aid_2, lap: 1, bitkey: 1, time_from_start: 5100)
SplitTime.create!(effort: joe_test, split: test_finish, lap: 1, bitkey: 1, time_from_start: 9000)
SplitTime.create!(effort: jane_test, split: test_start, lap: 1, bitkey: 1, time_from_start: 0)
SplitTime.create!(effort: jane_test, split: test_aid_1, lap: 1, bitkey: 1, time_from_start: 3000)
SplitTime.create!(effort: jane_test, split: test_aid_2, lap: 1, bitkey: 1, time_from_start: 3100)
SplitTime.create!(effort: jane_test, split: test_finish, lap: 1, bitkey: 1, time_from_start: 7500)

Stewardship.create!(user: third, organization: frozen_lips_org)
Stewardship.create!(user: fourth, organization: hardly_rocker_org)
