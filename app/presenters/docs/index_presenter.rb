# frozen_string_literal: true

module Docs
  class IndexPresenter < Docs::BasePresenter
    def category
      :index
    end

    def display_category
      'Documentation Index'
    end

    def items
      {
          contents: {display_topic: 'Contents', pages: ['Categories']},
      }
    end
  end
end
