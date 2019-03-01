# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit the spread page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event) { events(:hardrock_2015) }
  let(:subject_efforts) { event.efforts }

  scenario 'A visitor views the podium page' do
    visit spread_event_path(event)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario 'A user views the podium page' do
    login_as user, scope: :user

    visit spread_event_path(event)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario 'An admin views the podium page' do
    login_as admin, scope: :user

    visit spread_event_path(event)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario 'A user filters using the gender dropdown' do
    visit spread_event_path(event)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)

    click_link 'Female'
    page.find_button('Female')

    verify_efforts_present(subject_efforts.female)
    verify_efforts_absent(subject_efforts.male)
  end

  scenario 'A user chooses different display styles' do
    visit spread_event_path(event)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
    effort = event.efforts.find_by(bib_number: 1)

    click_link 'Elapsed'
    page.find_button('Elapsed')
    expect(find("#effort_#{effort.id}")).to have_content('23:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 5:13:00AM')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 05:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('01h07m00s')

    click_link 'AM/PM'
    page.find_button('AM/PM')
    expect(find("#effort_#{effort.id}")).not_to have_content('23:13:00')
    expect(find("#effort_#{effort.id}")).to have_content('Sat 5:13:00AM')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 05:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('01h07m00s')

    click_link '24-Hour'
    page.find_button('24-Hour')
    expect(find("#effort_#{effort.id}")).not_to have_content('23:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 5:13:00AM')
    expect(find("#effort_#{effort.id}")).to have_content('Sat 05:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('01h07m00s')

    click_link 'Segment'
    page.find_button('Segment')
    expect(find("#effort_#{effort.id}")).not_to have_content('23:13:00')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 5:13:00AM')
    expect(find("#effort_#{effort.id}")).not_to have_content('Sat 05:13:00')
    expect(find("#effort_#{effort.id}")).to have_content('01h07m00s')
  end

  def verify_efforts_present(efforts)
    efforts.each do |effort|
      verify_link_present(effort, :full_name)
    end
  end

  def verify_efforts_absent(efforts)
    efforts.each do |effort|
      verify_content_absent(effort, :full_name)
    end
  end
end
