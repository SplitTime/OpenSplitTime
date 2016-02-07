# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
# Environment variables (ENV['...']) can be set in the file .env file.

User.create!(first_name: 'Admin', last_name: 'User', role: :admin, email: 'user@example.com', password: 'password')
User.create!(first_name: 'Test', last_name: 'User', role: :user, email: 'tester@example.com', password: 'password')
User.create!(first_name: 'Third', last_name: 'User', role: :user, email: 'thirduser@example.com', password: 'password')
User.create!(first_name: 'Fourth', last_name: 'User', role: :user, email: 'fourthuser@example.com', password: 'password')

Country.create(code: 'US', name: 'United States of America')
Country.create(code: 'GB', name: 'United Kingdom')
Country.create(code: 'CA', name: 'Canada')

Course.create(name: 'Test Course CCW')
Course.create(name: 'Another Course')
Course.create(name: 'Nolans 140')

Race.create(name: 'Slo Mo 100')
Race.create(name: 'Frozen Lips 100')
Race.create(name: 'Hardly Rocker 100')

Location.create(name: 'Mountain Town', elevation: 2400, latitude: 40.1, longitude: -105)
Location.create(name: 'British Ghetto', elevation: 50, latitude: 55, longitude: 0)
Location.create(name: 'Typical Outback', elevation: 200, latitude: -43, longitude: 146.3)
Location.create(name: 'Mountain Hideout', elevation: 2900, latitude: 40.3, longitude: -105.05)

Event.create(course_id: 2, race_id: 3, name: 'Hardly Rocker 2010', start_date: "2010-08-10")
Event.create(course_id: 2, race_id: 2, name: 'Frozen Lips 2015', start_date: "2015-05-31")
Event.create(course_id: 1, race_id: nil, name: 'Test Event', start_date: "2012-08-08")

Participant.create(first_name: 'Joe', last_name: 'Hardman', gender: 'M', birthdate: "1989-12-15", city: 'Boulder', state: 'Colorado', country_id: 1, email: 'hardman@gmail.com', phone: nil)
Participant.create(first_name: 'Jane', last_name: 'Rockstar', gender: 'F', birthdate: "1985-09-20", city: 'Seattle', state: 'Washington', country_id: 1, email: nil, phone: '206-977-9777')
Participant.create(first_name: 'Basil', last_name: 'Smith', gender: 'M', birthdate: "1995-04-31", city: 'London', state: nil, country_id: 2, email: 'basil@uk.gov', phone: '02-998-33-55')
Participant.create(first_name: 'Jen', last_name: 'Huckster', gender: 'F', birthdate: nil, city: 'Vancouver', state: 'British Columbia', country_id: 3, email: 'jane@canuck.com', phone: '804-888-5555')

Effort.create(event_id: 3, participant_id: 4, wave: nil, bib_number: 99, city: 'Vancouver', state: 'British Columbia', country_id: 3, age: 50, start_time: "2012-08-08 05:00:00", finished: true)
Effort.create(event_id: 3, participant_id: 1, wave: nil, bib_number: 12, city: 'Boulder', state: 'Colorado', country_id: 1, age: 23, start_time: "2012-08-08 05:00:00", finished: true)
Effort.create(event_id: 1, participant_id: 2, wave: nil, bib_number: 1775, city: 'Atlanta', state: 'Georgia', country_id: 1, age: 24, start_time: "2010-08-10 06:00:00", finished: true)
Effort.create(event_id: 2, participant_id: 3, wave: nil, bib_number: 44, city: 'London', state: 'Surrey', country_id: 2, age: 20, start_time: "2015-05-31 07:00:00", finished: false)
Effort.create(event_id: 1, participant_id: 3, wave: nil, bib_number: 66, city: 'London', state: 'Surrey', country_id: 2, age: 15, start_time: "2010-08-10 06:00:00", finished: true)
Effort.create(event_id: 3, participant_id: 2, wave: nil, bib_number: 150, city: 'Nantucket', state: 'Massachusetts', country_id: 1, age: 26, start_time: "2012-08-08 05:00:00", finished: true)

Split.create(course_id: 1, location_id: 1, name: 'Test Starting Line', distance_from_start: 0, vert_gain_from_start: 0, vert_loss_from_start: 0, kind: 0)
Split.create(course_id: 1, location_id: 4, name: 'Test Aid Station In', distance_from_start: 6000, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
Split.create(course_id: 1, location_id: 4, name: 'Test Aid Station Out', distance_from_start: 6000, sub_order: 1, vert_gain_from_start: 500, vert_loss_from_start: 0, kind: 2)
Split.create(course_id: 1, location_id: 1, name: 'Test Finish Line', distance_from_start: 10000, vert_gain_from_start: 700, vert_loss_from_start: 700, kind: 1)

SplitTime.create(effort_id: 1, split_id: 1, time_from_start: 0)
SplitTime.create(effort_id: 1, split_id: 2, time_from_start: 4000)
SplitTime.create(effort_id: 1, split_id: 3, time_from_start: 4100)
SplitTime.create(effort_id: 1, split_id: 4, time_from_start: 8000)
SplitTime.create(effort_id: 2, split_id: 1, time_from_start: 0)
SplitTime.create(effort_id: 2, split_id: 2, time_from_start: 5000)
SplitTime.create(effort_id: 2, split_id: 3, time_from_start: 5100)
SplitTime.create(effort_id: 2, split_id: 4, time_from_start: 9000)
SplitTime.create(effort_id: 6, split_id: 1, time_from_start: 0)
SplitTime.create(effort_id: 6, split_id: 2, time_from_start: 3000)
SplitTime.create(effort_id: 6, split_id: 3, time_from_start: 3100)
SplitTime.create(effort_id: 6, split_id: 4, time_from_start: 7500)

Interest.create(user_id: 2, participant_id: 1, kind: :active)
Interest.create(user_id: 2, participant_id: 3, kind: :casual)
Interest.create(user_id: 2, participant_id: 4, kind: :casual)
Interest.create(user_id: 3, participant_id: 1, kind: :pending_active)
Interest.create(user_id: 3, participant_id: 2, kind: 0)
Interest.create(user_id: 4, participant_id: 2, kind: 1)
Interest.create(user_id: 4, participant_id: 3, kind: 0)
Interest.create(user_id: 4, participant_id: 4, kind: 2)

Ownership.create(user_id: 3, race_id: 2)
Ownership.create(user_id: 4, race_id: 3)