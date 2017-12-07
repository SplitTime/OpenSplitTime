module Persist
  class BulkUpdateAll
    def self.perform!(model, resources, update_fields)
      new(model, resources, update_fields).perform!
    end

    def initialize(model, resources, update_fields)
      @model = model
      @resources = resources
      @update_fields = update_fields
    end

    def perform!

    end

    private

    attr_reader :model, :resources, :update_fields
  end
end
