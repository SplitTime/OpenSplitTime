# frozen_string_literal: true

module Docs
  class GettingStartedPresenter < Docs::BasePresenter
    def category
      :getting_started
    end

    def display_category
      'Getting Started'
    end

    def items
      {
          overview: {display_topic: 'Overview', pages: ['Welcome', 'Organizations, Courses, and Events', 'Two Types of Time Records']},
          staging: {display_topic: 'Staging', pages: ['Create Your First Event Group', 'Duplicate an Existing Group', 'New Event With Existing Organization',
                        'Formatting Split Data for Import', 'Formatting Entrant Data for Import', 'Experiment']},
          terms: {display_topic: 'Terms', pages: ['Organization', 'Course', 'Split', 'Event Group', 'Event', 'Person', 'Entrant or Effort', 'Raw Time', 'Split Time']},
          support: {display_topic: 'Support', pages: ['Getting Help']}
      }
    end
  end
end
