# frozen_string_literal: true

module Persist
  class Base
    include Interactors::Errors
    include ActionView::Helpers::TextHelper

    def self.perform!(model, resources, options)
      new(model, resources, options).perform!
    end

    def initialize(model, resources, options)
      @model = model
      @resources = resources
      @update_fields = options[:update_fields].nil? ? [] : Array.wrap(options[:update_fields])
      @errors = []
      post_initialize(options)
      validate_setup
    end

    def post_initialize(options); end

    def perform!
      ActiveRecord::Base.transaction do
        persist_resources
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message)
    end

    private

    attr_reader :model, :resources, :update_fields, :errors

    def message
      if errors.present?
        "#{model_name.pluralize(resources.size)} could not be updated. "
      else
        "Updated #{pluralize(resources.size, model_name)}. "
      end
    end

    def model_name
      model.to_s.underscore.humanize(capitalize: false)
    end

    def validate_setup
      raise ArgumentError, 'model must be provided' unless model && model.is_a?(Class)
      raise ArgumentError, 'resources must be provided' unless resources && resources.is_a?(Enumerable)
      raise ArgumentError, 'all resources must be members of the model class' unless resources.all? { |resource| resource.class == model }
      validate_additional_setup
    end

    def validate_additional_setup; end
  end
end
