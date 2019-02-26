# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Visit the home page' do
  let(:user) { users(:third_user) }
  let(:admin) { users(:admin_user) }

  let(:recent_event_groups) { [event_groups(:sum), event_groups(:dirty_30), event_groups(:rufa_2017), event_groups(:hardrock_2016)] }

  scenario 'The user is a visitor' do
    visit root_path

    verify_public_links_present
  end

  scenario 'The user is a non-admin user' do
    login_as user, scope: :user
    visit root_path

    verify_public_links_present
  end

  scenario 'The user is an admin user' do
    login_as admin, scope: :user
    visit root_path

    verify_public_links_present
  end


  def verify_public_links_present
    recent_event_groups.each(&method(:verify_link_present))
  end
end
