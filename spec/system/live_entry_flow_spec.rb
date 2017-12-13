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
    let(:event) { create(:event, event_group: event_group, course: course, laps_required: 1, start_time_in_home_zone: '2017-10-10 08:00:00') }

    context 'for previously unstarted efforts' do
      scenario 'Add and submit times' do
        login_and_check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times).to be_empty
        expect(efforts.second.split_times).to be_empty
        expect(efforts.third.split_times).to be_empty

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        submit_all_efforts

        expect(efforts.first.split_times).to be_one
        expect(efforts.second.split_times).to be_one
        expect(efforts.third.split_times).to be_empty

        verify_workspace_is_empty
      end
    end

    context 'for previously started efforts' do
      before do
        split_1 = ordered_splits.first
        split_2 = ordered_splits.second
        efforts.each do |effort|
          effort.split_times.create!(lap: 1, split: split_1, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
          effort.split_times.create!(lap: 1, split: split_2, bitkey: SubSplit::IN_BITKEY, time_from_start: 1.hour)
        end
      end

      scenario 'Add and submit times' do
        login_and_check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times.size).to eq(2)
        expect(efforts.second.split_times.size).to eq(2)
        expect(efforts.third.split_times.size).to eq(2)

        select ordered_splits.third.base_name, from: 'split-select'

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '10:45:45'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '11:00:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)
        expect(local_workspace).not_to have_content(efforts.third.full_name)

        submit_all_efforts

        verify_workspace_is_empty

        expect(efforts.first.split_times.size).to eq(3)
        expect(efforts.second.split_times.size).to eq(3)
        expect(efforts.third.split_times.size).to eq(2)

      end

      scenario 'Add and discard times' do
        login_and_check_setup
        expect(page).not_to have_field('js-lap-number')

        expect(efforts.first.split_times.size).to eq(2)
        expect(efforts.second.split_times.size).to eq(2)

        select ordered_splits.third.base_name, from: 'split-select'

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:45:45'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).not_to have_content(efforts.second.full_name)

        fill_in bib_number_field, with: efforts.second.bib_number
        fill_in time_in_field, with: '09:00:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts.first.full_name)
        expect(local_workspace).to have_content(efforts.second.full_name)

        discard_all_efforts

        expect(efforts.first.split_times.size).to eq(2)
        expect(efforts.second.split_times.size).to eq(2)

        verify_workspace_is_empty
      end

      scenario 'Change a start split_time forwards and backwards' do
        login_and_check_setup
        expect(page).not_to have_field('js-lap-number')

        effort = efforts.first
        ordered_split_times = effort.ordered_split_times

        expect(ordered_split_times.size).to eq(2)
        expect(ordered_split_times.first.time_from_start).to eq(0)
        expect(ordered_split_times.first.military_time).to eq('08:00:00')
        expect(ordered_split_times.second.time_from_start).to eq(3600)

        select ordered_splits.first.base_name, from: 'split-select'

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '08:15:00'
        add_button.click

        submit_all_efforts

        effort.reload
        ordered_split_times = effort.ordered_split_times
        expect(ordered_split_times.size).to eq(2)
        expect(ordered_split_times.first.time_from_start).to eq(0)

        # Because starting split time_from_start was moved forward by 900 seconds
        expect(ordered_split_times.second.time_from_start).to eq(2700) # 3600 - 900
        expect(effort.start_offset).to eq(900)

        verify_workspace_is_empty

        fill_in bib_number_field, with: efforts.first.bib_number
        fill_in time_in_field, with: '07:45:00'
        add_button.click

        submit_all_efforts

        effort.reload
        ordered_split_times = effort.ordered_split_times
        expect(ordered_split_times.size).to eq(2)
        expect(ordered_split_times.first.time_from_start).to eq(0)

        # Because starting split time_from_start was moved back by 1800 seconds
        expect(ordered_split_times.second.time_from_start).to eq(4500) # 2700 + 1800
        expect(effort.start_offset).to eq(-900)

        verify_workspace_is_empty
      end
    end
  end

  def login_and_check_setup
    login_as user
    visit live_entry_live_event_path(event)
    wait_for_ajax

    check_setup
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
