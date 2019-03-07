# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'visit an event series page' do
  let(:user) { users(:third_user) }
  let(:owner) { users(:fourth_user) }
  let(:steward) { users(:fifth_user) }
  let(:admin) { users(:admin_user) }

  before do
    organization.update(created_by: owner.id)
    organization.stewards << steward
  end

  let(:person_1) { people(:series_finisher) }
  let(:person_2) { people(:slow_finisher) }
  let(:person_3) { people(:finished_second) }
  let(:organization) { subject_series.organization }
  let(:events) { subject_series.events }

  context 'when the user is a visitor' do
    context 'when all categories are populated' do
      let(:subject_series) { event_series(:d30_short_series) }

      scenario 'Visit the page' do
        visit event_series_path(subject_series)
        verify_page_header
        verify_event_links
      end
    end
  end

  def verify_page_header
    verify_content_present(subject_series)
    verify_content_present(organization)
  end

  def verify_event_links
    events.each(&method(:verify_link_present))
  end
end
