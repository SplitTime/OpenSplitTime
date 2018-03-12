# frozen_string_literal: true

module Persist

  # This class uses the activerecord-import gem to optimize updates wherein the number of records is large
  # and the universe of values for updated columns is also large. For example, this class performs
  # well updating time_from_start attributes over many split_times.

  # Validations are run only if validate: true is passed in the options hash.

  # No callbacks are run except, in the case of models with FriendlyId, if no slug exists,
  # before_validation callbacks are run to build the slug.

  class BulkUpsert < Persist::Base

    def post_initialize(options)
      @validate = options[:validate]
    end

    private

    attr_reader :validate

    def persist_resources
      build_missing_slugs
      model.import(resources, on_duplicate_key_update: update_fields, validate: validate?)
    rescue ActiveRecord::ActiveRecordError => exception
      errors << active_record_error(exception)
    end

    def build_missing_slugs
      resources.each do |resource|
        resource.run_callbacks(:validation) { false } if resource.respond_to?(:slug) && resource.slug.nil?
      end
    end

    def validate?
      validate.nil? ? false : validate
    end
  end
end
