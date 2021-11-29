# frozen_string_literal: true

module Docs
  class ManagementPresenter < Docs::BasePresenter
    def category
      :management
    end

    def display_category
      'Event Management'
    end

    def items
      {
        overview: {
          display_topic: 'Overview',
          pages: [
            'Summary of Steps',
          ]},
        prep: {
          display_topic: 'Preparation',
          pages: [
            'Going Public and Live',
            'Explaining How to Follow',
            'Obtaining Equipment',
            'Caring for Equipment',
            'Training Crews',
            'Predicting Traffic',
          ]},
        start: {
          display_topic: 'Starting',
          pages: [
            'Overview',
            'Checking In',
            'Changing Entrants',
            'Starting Entrants',
          ]},
        monitor: {
          display_topic: 'Monitoring',
          pages: [
            'Tools',
            'Full Results',
            'Watching Progress',
            'Aid Station Overview',
            'Aid Station Detail',
            'Problem Efforts',
            'Raw Times List',
            'Raw Times Splits',
            'Finish Line',
          ]},
        enter: {
          display_topic: 'Entering and Editing Times',
          pages: [
            'Live Entry',
            'Direct Edit',
            'Rebuilding an Effort',
            'Reviewing Raw Times',
            'Understanding Problems',
            'Analyzing Problem Efforts',
            'Using Raw Times',
            'Auditing an Effort',
          ]},
        wind_up: {
          display_topic: 'Winding Up',
          pages: [
            'Setting Stops',
            'Disabling Live Entry',
            'Exporting Data',
          ]},
        support: {
          display_topic: 'Support',
          pages: ['Getting Help']}
      }
    end
  end
end
