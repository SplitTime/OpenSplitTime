module Deprecation
  class SubstituteSlug
    def self.perform(model, slug)
      Deprecation::Slugs.fetch(model, slug) || slug
    end
  end
end
