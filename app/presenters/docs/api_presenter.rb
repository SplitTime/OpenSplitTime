# frozen_string_literal: true

module Docs
  class ApiPresenter < Docs::BasePresenter
    def category
      :api
    end

    def display_category
      'OpenSplitTime API'
    end

    def items
      {
          credentials: {display_topic: 'Credentials', pages: ['Signing Up']},
          key: {display_topic: 'API Keys', pages: ['Getting an API Key', 'Security and Lifespan']},
          query: {display_topic: 'Querying the API', pages: ['Index Queries', 'Individual Queries', 'Special Queries', 'Performance']}
      }
    end
  end
end
