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
          jwt: {display_topic: 'JSON Web Tokens', pages: ['Getting a Token', 'Security and Lifespan']},
          query: {display_topic: 'Querying the API', pages: ['Index Queries', 'Individual Queries', 'Special Queries', 'Performance']}
      }
    end
  end
end
