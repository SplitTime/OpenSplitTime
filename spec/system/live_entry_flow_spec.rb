# frozen_string_literal: true

require 'rails_helper'
include BitkeyDefinitions

RSpec.describe 'Live entry app flow', type: :system, js: true do
  before { allow(Pusher).to receive(:trigger) }

  let(:user) { users(:admin_user) }
  let(:event_1) { events(:sum_100k) }
  let(:event_2) { events(:sum_55k) }
  let(:event_group) { event_groups(:sum) }
  let(:ordered_splits_1) { event_1.ordered_splits }
  let(:ordered_splits_2) { event_2.ordered_splits }

  let(:start_time_1) { event_1.start_time }
  let(:start_time_2) { event_2.start_time }

  let(:add_efforts_form) { find_by_id('js-add-effort-form') }
  let(:local_workspace) { find_by_id('js-local-workspace-table_wrapper') }

  let(:bib_number_field) { 'js-bib-number' }
  let(:time_in_field) { 'js-time-in' }
  let(:time_out_field) { 'js-time-out' }
  let(:add_button) { find_by_id('js-add-to-cache') }
  let(:slider_effort_name) { find_by_id('js-effort-name') }
  let(:submit_all_button) { find_by_id('js-submit-all-time-rows') }
  let(:discard_all_button) { find_by_id('js-delete-all-time-rows') }


  context 'for previously unstarted efforts' do
    let(:effort_1) { efforts(:sum_100k_un_started) }
    let(:effort_2) { efforts(:sum_55k_not_started) }
    let(:subject_efforts) { [effort_1, effort_2] }

    scenario 'Add and submit times' do
      login_and_check_setup
      expect(page).not_to have_field('js-lap-number')

      expect(subject_efforts.map(&:split_times)).to all be_empty

      fill_in bib_number_field, with: effort_1.bib_number
      fill_in time_in_field, with: '08:00'
      expect(slider_effort_name).to have_content(effort_1.full_name)
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).not_to have_content(effort_2.full_name)

      fill_in bib_number_field, with: effort_2.bib_number
      fill_in time_in_field, with: '09:00'
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).to have_content(effort_2.full_name)

      submit_all_efforts

      reload_all_efforts

      expect(effort_1.split_times.size).to eq(1)
      expect(effort_2.split_times.size).to eq(1)

      verify_workspace_is_empty
    end
  end

  context 'for previously started efforts' do
    let(:effort_1) { efforts(:sum_100k_progress_cascade) }
    let(:effort_2) { efforts(:sum_55k_progress_rolling) }
    let(:subject_efforts) { [effort_1, effort_2] }

    scenario 'Add and submit times' do
      login_and_check_setup
      expect(page).not_to have_field('js-lap-number')

      expect(effort_1.split_times.size).to eq(7)
      expect(effort_2.split_times.size).to eq(5)

      select ordered_splits_1[5].base_name, from: 'js-station-select'

      fill_in bib_number_field, with: effort_1.bib_number
      fill_in time_in_field, with: '19:00:00'
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).not_to have_content(effort_2.full_name)

      fill_in bib_number_field, with: effort_2.bib_number
      fill_in time_in_field, with: '13:00:00'
      fill_in time_out_field, with: '13:20:00'
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).to have_content(effort_2.full_name)

      submit_all_efforts

      reload_all_efforts

      expect(effort_1.split_times.size).to eq(8)
      expect(effort_2.split_times.size).to eq(7)

      verify_workspace_is_empty
    end

    scenario 'Add and discard times' do
      login_and_check_setup
      expect(page).not_to have_field('js-lap-number')

      expect(effort_1.split_times.size).to eq(7)
      expect(effort_2.split_times.size).to eq(5)

      select ordered_splits_1[5].base_name, from: 'js-station-select'

      fill_in bib_number_field, with: effort_1.bib_number
      fill_in time_in_field, with: '08:45:45'
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).not_to have_content(effort_2.full_name)

      fill_in bib_number_field, with: effort_2.bib_number
      fill_in time_in_field, with: '09:00:00'
      add_button.click
      wait_for_css

      expect(local_workspace).to have_content(effort_1.full_name)
      expect(local_workspace).to have_content(effort_2.full_name)

      discard_all_efforts

      reload_all_efforts

      expect(effort_1.split_times.size).to eq(7)
      expect(effort_2.split_times.size).to eq(5)

      verify_workspace_is_empty
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
    expect(add_efforts_form).to have_field('js-bib-number')
    expect(add_efforts_form).to have_field('js-time-in', disabled: false)
    expect(add_efforts_form).to have_field('js-time-out', disabled: true)
    expect(add_efforts_form).to have_select('js-station-select', options: ordered_splits_1.map(&:base_name))
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
    expect(page).to have_button('js-delete-all-warning', disabled: true)
    wait_for_css
    discard_all_button.click
  end

  def reload_all_efforts
    subject_efforts.each(&:reload)
  end

  def verify_workspace_is_empty
    expect(local_workspace).to have_content('No data available in table')
  end
end
