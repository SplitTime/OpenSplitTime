require "rails_helper"

RSpec.describe "visit the summary page" do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }
  let(:event) { events(:hardrock_2015) }
  let(:subject_efforts) { event.efforts }

  scenario "A visitor views the summary page" do
    visit_page
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario "A user views the summary page" do
    login_as user, scope: :user

    visit_page
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario "An admin views the summary page" do
    login_as admin, scope: :user

    visit_page
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts)
  end

  scenario "With finished=true parameter" do
    visit summary_event_path(event, finished: true)
    expect(page).to have_content(event.name)
    verify_efforts_present(subject_efforts.finished)
    verify_efforts_absent(subject_efforts.unfinished)
  end

  def verify_efforts_absent(efforts)
    efforts.each do |effort|
      verify_content_absent(effort, :full_name)
    end
  end

  def verify_efforts_present(efforts)
    efforts.each do |effort|
      verify_content_present(effort, :full_name)
    end
  end

  def visit_page
    visit summary_event_path(event)
  end
end
