require 'rails_helper'

RSpec.describe 'Live entry app flow', type: :system, js: true do
  let(:user) { create(:user) }
  let(:course) { create(:course_with_standard_splits, :with_description, created_by: user.id) }
  let(:organization) { create(:organization, created_by: user.id) }
  let(:event_group) { create(:event_group, organization: organization, available_live: true) }
  before { event.splits << course.splits }
  let(:efforts) { create_list(:effort, 3, event: event) }
  let(:ordered_splits) { event.ordered_splits }

  let(:add_efforts_form) { find_by_id('js-add-effort-form') }
  let(:local_workspace) { find_by_id('js-provisional-data-table_wrapper') }

  let(:bib_number_field) { 'js-bib-number' }
  let(:time_in_field) { 'js-time-in' }
  let(:time_out_field) { 'js-time-out' }
  let(:add_button) { find_by_id('js-add-to-cache') }
  let(:submit_all_button) { find_by_id('js-submit-all-efforts') }
  let(:discard_all_button) { find_by_id('js-delete-all-efforts') }

  context 'For a single-lap event' do
    let(:event) { create(:event, event_group: event_group, course: course, laps_required: 1, start_time: '2017-10-10 08:00:00') }

    context 'for previously unstarted efforts' do
      scenario 'Add and submit times' do
        login_as user
        visit live_entry_live_event_path(event)
        wait_for_ajax

        check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times).to be_empty
        expect(efforts.second.split_times).to be_empty
        expect(efforts.third.split_times).to be_empty

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.third.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).to have_content(efforts.third.full_name)

        submit_all_efforts

        expect(efforts.first.split_times).to be_one
        expect(efforts.second.split_times).to be_one
        expect(efforts.third.split_times).to be_one

        verify_workspace_is_empty
      end
    end

    context 'for previously started efforts' do
      before do
        split = ordered_splits.first
        efforts.each do |effort|
          SplitTime.create!(effort: effort, split: split, bitkey: SubSplit::IN_BITKEY, lap: 1, time_from_start: 0)
        end
      end

      scenario 'Add and submit times' do
        login_as user
        visit live_entry_live_event_path(event)
        wait_for_ajax

        check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times).to be_one
        expect(efforts.second.split_times).to be_one
        expect(efforts.third.split_times).to be_one

        select ordered_splits.second.base_name, from: 'split-select'

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:45:45'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '09:00:00'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.third.bib_number
        fill_in time_in_field, with: '09:15:15'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).to have_content(efforts.third.full_name)

        submit_all_efforts

        expect(efforts.first.split_times).to be_many
        expect(efforts.second.split_times).to be_many
        expect(efforts.third.split_times).to be_many

        verify_workspace_is_empty
      end

      scenario 'Add and discard times' do
        login_as user
        visit live_entry_live_event_path(event)
        wait_for_ajax

        check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times).to be_one
        expect(efforts.second.split_times).to be_one

        select ordered_splits.second.base_name, from: 'split-select'

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:45:45'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '09:00:00'
        add_button.click

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)

        discard_all_efforts

        expect(efforts.first.split_times).to be_one
        expect(efforts.second.split_times).to be_one

        verify_workspace_is_empty
      end
    end
  end

  def check_setup
    expect(page).to have_content(event.name)
    expect(page).to have_content('Live Data Entry')
    verify_workspace_is_empty
    expect(add_efforts_form).to have_select('split-select')
    expect(add_efforts_form).to have_field('js-bib-number')
    expect(add_efforts_form).to have_field('js-time-in', disabled: false)
    expect(add_efforts_form).to have_field('js-time-out', disabled: true)
    expect(add_efforts_form).to have_field('js-pacer-in', checked: false, disabled: false)
    expect(add_efforts_form).to have_field('js-pacer-out', checked: false, disabled: true)
  end

  def submit_all_efforts
    sleep(2)
    submit_all_button.click
    wait_for_ajax
  end

  def discard_all_efforts
    discard_all_button.click
    expect(page).to have_button('js-delete-all-warning', disabled: true)
    wait_for_css
    discard_all_button.click
  end

  def verify_workspace_is_empty
    expect(local_workspace).to have_content('No data available in table')
  end
end
