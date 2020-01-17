# frozen_string_literal: true

module Docs
  class ContentsPresenter < Docs::BasePresenter
    def category
      :contents
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
