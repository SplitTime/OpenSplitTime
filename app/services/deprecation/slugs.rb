module Deprecation
  class Slugs
    def self.fetch(model, slug)
      raise NotImplementedError, "Slug deprecation for model #{model} has not been implemented" unless slugs[model]
      slugs[model][slug]
    end

    def self.slugs
      {events: {
              '2017-rattlesnake-ramble-kids-race' => '2017-rattlesnake-ramble-kids-run'
          }}.with_indifferent_access
    end

  end
end
