# frozen_string_literal: true

module DocsHelper
  def build_sidebar_menu(items, action)
    default_topic = items.keys.first
    default_page = 1

    content_tag(:div, class: 'list-group list-group-flush') do
      items.each do |topic, pages|
        concat(content_tag(:div, topic, class: 'sidebar-heading'))
        pages.each.with_index(1) do |page, i|
          topic_matches = (params[:topic] || default_topic).downcase == topic.downcase
          page_matches = (params[:page] || default_page).to_i == i
          active = topic_matches && page_matches ? 'active' : nil
          class_text = ['list-group-item list-group-item-action bg-light', active].compact.join(' ')

          concat(link_to page, {controller: :visitors, action: action, topic: topic.downcase, page: i}, class: class_text)
        end
      end
    end
  end

  def getting_started_sidebar_menu
    items = {
        'Overview' => ['Welcome', 'Organizations, Courses, and Events', 'Two Types of Time Records'],
        'Staging' => ['Create Your First Event Group', 'Duplicate an Existing Group', 'New Event With Existing Organization',
        'Formatting Split Data for Import', 'Formatting Entrant Data for Import', 'Experiment'],
        'Terms' => ['Organization', 'Course', 'Split', 'Event Group', 'Event', 'Person', 'Entrant', 'Raw Time', 'Split Time']
    }

    build_sidebar_menu(items, :getting_started)
  end

  def management_sidebar_menu
    items = {
        'Overview' => ['Summary of Steps'],
        'Preparation' => ['Going Public and Live', 'Explaining How to Follow', 'Training Crews', 'Preparing Equipment'],
        'Check In and Start' => ['Checking In', 'Changing Entrants', 'Starting Entrants'],
        'Monitoring' => ['Tools', 'Looking for Holes', 'Watching Progress', 'Aid Station Summary', 'Aid Station Detail'],
        'Entering and Editing Times' => ['Live Entry', 'Direct Edit', 'Rebuilding an Effort', 'Finding Problems', 'Sleuthing'],
        'Winding Up' => ['Setting Stops', 'Disabling Live Entry', 'Exporting Data'],
        'Support' => ['Getting Help']
    }

    build_sidebar_menu(items, :management)
  end

  def ost_remote_sidebar_menu
    items = {
        'Setup' => ['Welcome', 'Your Event and Aid Station'],
        'Menu' => ['Overview', 'Live Entry', 'Review/Sync', 'Cross Check', 'Change Station', 'Logout'],
        'Usage' => ['The Timing Station', 'Recording Tips']
    }

    build_sidebar_menu(items, :ost_remote)
  end
end
