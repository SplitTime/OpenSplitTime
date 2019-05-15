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
          overview: {display_topic: 'Overview', pages: ['Summary of Steps']},
          prep: {display_topic: 'Preparation', pages: ['Going Public and Live', 'Explaining How to Follow', 'Preparing Equipment', 'Training Crews']},
          start: {display_topic: 'Starting', pages: ['Overview', 'Checking In', 'Changing Entrants', 'Starting Entrants']},
          monitor: {display_topic: 'Monitoring', pages: ['Tools', 'Full Results', 'Watching Progress', 'Aid Station Summary', 'Aid Station Detail', 'Problem Efforts']},
          enter: {display_topic: 'Entering and Editing Times', pages: ['Live Entry', 'Direct Edit', 'Rebuilding an Effort', 'Finding Problems', 'Sleuthing']},
          wind_up: {display_topic: 'Winding Up', pages: ['Setting Stops', 'Disabling Live Entry', 'Exporting Data']},
          support: {display_topic: 'Support', pages: ['Getting Help']}
      }
    end
  end
end
