require "rails_helper"

RSpec.describe "visit a person show page" do
  let(:person) { people(:finished_first_utah_us) }
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  context "When the person is visible" do
    scenario "Visit the page" do
      visit_page

      verify_content_present
    end

    scenario "The user is a non-admin" do
      login_as user, scope: :user
      visit_page

      verify_content_present
    end

    scenario "The user is an admin user" do
      login_as admin, scope: :user
      visit_page

      verify_content_present
    end
  end

  context "When the person is hidden" do
    before { person.update(concealed: true) }
    scenario "The user is a visitor" do
      verify_record_not_found
    end

    scenario "The user is a non-admin" do
      login_as user, scope: :user

      verify_record_not_found
    end

    scenario "The user is an admin user" do
      login_as admin, scope: :user
      visit_page

      verify_content_present
    end
  end

  context "When the current user is authorized to claim the person", js: true do
    before { person.update(first_name: "Third", last_name: "User") }

    scenario "The user claims the person" do
      login_as user, scope: :user
      visit_page

      expect do
        accept_confirm do
          click_button "This is me"
        end

        expect(page).to have_content("Hey, this is me!")
        expect(page).to have_current_path(person_path(person))
      end.to change { person.reload.claimant }.from(nil).to(user)
    end
  end

  context "When the current user is not authorized to claim the person" do
    before { person.update(first_name: "Different", last_name: "Person") }

    scenario "The user cannot claim the person" do
      login_as user, scope: :user
      visit_page

      expect(page).not_to have_button("This is me")
    end
  end

  def verify_page_header
    expect(page).to have_content(person.full_name)
    expect(page).to have_link("People", href: people_path)
  end

  def verify_efforts
    person.efforts.each { |effort| verify_link_present(effort, :event_name) }
  end

  def verify_content_present
    verify_page_header
    expect(person.efforts.visible.size).to eq(1)
    verify_efforts
  end

  def verify_record_not_found
    expect { visit person_path(person) }.to raise_error ::ActiveRecord::RecordNotFound
  end

  def visit_page
    visit person_path(person)
  end
end
