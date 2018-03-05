require 'rails_helper'

RSpec.describe 'Group live entry app flow', type: :system, js: true do
  let!(:user) { create(:user) }
  let!(:course_1) { create(:course, :with_description, created_by: user.id) }
  let!(:course_2) { create(:course, :with_description, created_by: user.id) }
  let!(:start_split_1) { create(:start_split, base_name: 'Start') }
  let!(:aid_1_split_1) { create(:split, base_name: 'Molas Pass', distance_from_start: 8000) }
  let!(:aid_2_split_1) { create(:split, base_name: 'Rolling Pass', distance_from_start: 15000) }
  let!(:finish_split_1) { create(:finish_split, base_name: 'Finish', distance_from_start: 20000) }
  let!(:splits_1) { [start_split_1, aid_1_split_1, aid_2_split_1, finish_split_1] }
  let!(:start_split_2) { create(:start_split, base_name: 'Start') }
  let!(:aid_1_split_2) { create(:split, base_name: 'Rolling Pass', distance_from_start: 6000) }
  let!(:finish_split_2) { create(:finish_split, base_name: 'Finish', distance_from_start: 10000) }
  let!(:splits_2) { [start_split_2, aid_1_split_2, finish_split_2] }
  let!(:organization) { create(:organization, created_by: user.id) }
  let!(:event_group) { create(:event_group, organization: organization, available_live: true) }
  before do
    course_1.splits << splits_1
    event_1.splits << course_1.splits
    course_2.splits << splits_2
    event_2.splits << course_2.splits
  end
  let!(:efforts_1) { create_list(:effort, 2, :with_bib_number, event: event_1) }
  let!(:efforts_2) { create_list(:effort, 2, :with_bib_number, event: event_2) }
  let!(:ordered_splits_1) { event_1.ordered_splits }
  let!(:ordered_splits_2) { event_2.ordered_splits }

  let(:add_efforts_form) { find_by_id('js-group-add-effort-form') }
  let(:local_workspace) { find_by_id('js-group-local-workspace-table_wrapper') }

  let(:bib_number_field) { 'js-group-bib-number' }
  let(:time_in_field) { 'js-group-time-in' }
  let(:time_out_field) { 'js-group-time-out' }
  let(:add_button) { find_by_id('js-group-add-to-cache') }
  let(:slider_effort_name) { find_by_id('js-group-effort-name') }
  let(:submit_all_button) { find_by_id('js-group-submit-all-efforts') }
  let(:discard_all_button) { find_by_id('js-group-delete-all-efforts') }

  context 'For single-lap events' do
    let!(:event_1) { create(:event, event_group: event_group, course: course_1, laps_required: 1, start_time_in_home_zone: '2017-10-10 08:00:00') }
    let!(:event_2) { create(:event, event_group: event_group, course: course_2, laps_required: 1, start_time_in_home_zone: '2017-10-10 09:00:00') }

    context 'for previously unstarted efforts' do
      scenario 'Add and submit times' do
        login_and_check_setup
        expect(page).not_to have_field('js-group-lap-number')

        expect(Effort.all.map(&:split_times)).to all be_empty

        fill_in bib_number_field, with: efforts_1.first.bib_number
        fill_in time_in_field, with: '08:00'
        expect(slider_effort_name).to have_content(efforts_1.first.full_name)
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).not_to have_content(efforts_1.second.full_name)
        expect(local_workspace).not_to have_content(efforts_2.first.full_name)
        expect(local_workspace).not_to have_content(efforts_2.second.full_name)

        fill_in bib_number_field, with: efforts_2.first.bib_number
        fill_in time_in_field, with: '08:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).not_to have_content(efforts_1.second.full_name)
        expect(local_workspace).to have_content(efforts_2.first.full_name)
        expect(local_workspace).not_to have_content(efforts_2.second.full_name)

        submit_all_efforts

        expect(efforts_1.first.split_times).to be_one
        expect(efforts_1.second.split_times).to be_empty
        expect(efforts_2.first.split_times).to be_one
        expect(efforts_2.second.split_times).to be_empty

        verify_workspace_is_empty
      end
    end

    context 'for previously started efforts' do
      before do
        efforts_1.each do |effort|
          effort.split_times.create!(lap: 1, split: ordered_splits_1.first, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
          effort.split_times.create!(lap: 1, split: ordered_splits_1.second, bitkey: SubSplit::IN_BITKEY, time_from_start: 1.hour)
        end

        efforts_2.each do |effort|
          effort.split_times.create!(lap: 1, split: ordered_splits_2.first, bitkey: SubSplit::IN_BITKEY, time_from_start: 0)
        end
      end

      scenario 'Add and submit times' do
        login_and_check_setup
        expect(page).not_to have_field('js-group-lap-number')

        expect(efforts_1.map(&:split_times).map(&:size)).to all eq(2)
        expect(efforts_2.map(&:split_times).map(&:size)).to all eq(1)

        select ordered_splits_1.third.base_name, from: 'js-group-station-select'

        fill_in bib_number_field, with: efforts_1.first.bib_number
        fill_in time_in_field, with: '10:45:45'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).not_to have_content(efforts_1.second.full_name)

        fill_in bib_number_field, with: efforts_1.second.bib_number
        fill_in time_in_field, with: '11:00:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).to have_content(efforts_1.second.full_name)

        submit_all_efforts

        verify_workspace_is_empty

        expect(efforts_1.first.split_times.size).to eq(3)
        expect(efforts_1.second.split_times.size).to eq(3)
        expect(efforts_2.map(&:split_times).map(&:size)).to all eq(1)
      end

      scenario 'Add and discard times' do
        login_and_check_setup
        expect(page).not_to have_field('js-group-lap-number')

        expect(efforts_1.map(&:split_times).map(&:size)).to all eq(2)
        expect(efforts_2.map(&:split_times).map(&:size)).to all eq(1)

        select ordered_splits_1.third.base_name, from: 'js-group-station-select'

        fill_in bib_number_field, with: efforts_1.first.bib_number
        fill_in time_in_field, with: '08:45:45'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).not_to have_content(efforts_1.second.full_name)

        fill_in bib_number_field, with: efforts_1.second.bib_number
        fill_in time_in_field, with: '09:00:00'
        add_button.click
        wait_for_css

        expect(local_workspace).to have_content(efforts_1.first.full_name)
        expect(local_workspace).to have_content(efforts_1.second.full_name)

        discard_all_efforts

        expect(efforts_1.map(&:split_times).map(&:size)).to all eq(2)

        verify_workspace_is_empty
      end

      scenario 'Change a start split_time forwards and backwards' do
        login_and_check_setup
        expect(page).not_to have_field('js-group-lap-number')

        effort = efforts_1.first
        ordered_split_times = effort.ordered_split_times

        expect(ordered_split_times.size).to eq(2)
        expect(ordered_split_times.first.time_from_start).to eq(0)
        expect(ordered_split_times.first.military_time).to eq('08:00:00')
        expect(ordered_split_times.second.time_from_start).to eq(3600)

        select ordered_splits_1.first.base_name, from: 'js-group-station-select'

        fill_in bib_number_field, with: effort.bib_number
        fill_in time_in_field, with: '08:15:00'
        add_button.click

        submit_time_row(0)

        effort.reload
        ordered_split_times = effort.ordered_split_times
        expect(ordered_split_times.size).to eq(2)
        expect(ordered_split_times.first.time_from_start).to eq(0)

        # Because starting split time_from_start was moved forward by 900 seconds
        expect(ordered_split_times.second.time_from_start).to eq(2700) # 3600 - 900
        expect(effort.start_offset).to eq(900)

        verify_workspace_is_empty

        fill_in bib_number_field, with: effort.bib_number
        fill_in time_in_field, with: '07:45:00'
        add_button.click

        submit_time_row(0)

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
    visit live_entry_live_event_group_path(event_group)
    wait_for_ajax

    check_setup
  end

  def check_setup
    expect(page).to have_content(event_group.name)
    verify_workspace_is_empty
    expect(add_efforts_form).to have_field('js-group-bib-number')
    expect(add_efforts_form).to have_field('js-group-time-in', disabled: false)
    expect(add_efforts_form).to have_field('js-group-time-out', disabled: true)
    expect(add_efforts_form).to have_select('js-group-station-select', options: ['Start', 'Molas Pass', 'Rolling Pass', 'Finish'])
  end

  def submit_all_efforts
    sleep(2.5)
    submit_all_button.click
    sleep(1)
  end

  def submit_time_row(index)
    sleep(2.5)
    local_workspace.find('tbody').all('tr')[index].find('.submit-effort').click
    sleep(1)
  end

  def discard_all_efforts
    discard_all_button.click
    expect(page).to have_button('js-group-delete-all-warning', disabled: true)
    wait_for_css
    discard_all_button.click
  end

  def verify_workspace_is_empty
    expect(local_workspace).to have_content('No data available in table')
  end
end
