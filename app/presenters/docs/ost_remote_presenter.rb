# frozen_string_literal: true

module Docs
  class OstRemotePresenter < Docs::BasePresenter
    def category
      :ost_remote
    end

    def display_category
      'OST Remote'
    end

    def items
      {
          setup: {display_topic: 'Setup', pages: ['Welcome', 'Your Event and Aid Station']},
          menu: {display_topic: 'Menu', pages: ['Overview', 'Live Entry', 'Review/Sync', 'Cross Check', 'Change Station', 'Logout']},
          usage: {display_topic: 'Usage', pages: ['The Timing Station', 'Recording Tips']}
      }
    end
  end
end
