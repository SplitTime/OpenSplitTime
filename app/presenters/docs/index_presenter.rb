# frozen_string_literal: true

module Docs
  class IndexPresenter < Docs::BasePresenter
    def category
      :documentation
    end

    def display_category
      'Documentation Index'
    end

    def items
      {
          index: {display_topic: 'Index', pages: ['Categories']},
      }
    end
  end
end
