module Persist
  class BulkUpdateAll
    def self.perform!(model, resources, update_fields)
      new(model, resources, update_fields).perform!
    end

    def initialize(model, resources, update_fields)
      @model = model
      @resources = resources
      @update_fields = update_fields && Array.wrap(update_fields)
      validate_setup
    end

    def perform!
      grouped_resources.each do |value_pairs, selected_resources|
        model.where(id: selected_resources).update_all(value_pairs)
      end
    end

    private

    attr_reader :model, :resources, :update_fields

    def grouped_resources
      @grouped_resources ||= changed_resources.group_by { |resource| update_fields.map { |field| [field, resource.send(field)] }.to_h }
    end

    def changed_resources
      resources.select(&:changed?)
    end

    def validate_setup
      raise ArgumentError, 'model must be provided' unless model && model.is_a?(Class)
      raise ArgumentError, 'resources must be provided' unless resources && resources.is_a?(Enumerable)
      raise ArgumentError, 'update_fields must be provided' unless update_fields
      raise ArgumentError, 'all resources must be members of the model class' unless resources.all? { |resource| resource.class == model }
    end
  end
end
