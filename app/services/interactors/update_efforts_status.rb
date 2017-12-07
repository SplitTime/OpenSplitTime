module Interactors
  class UpdateEffortsStatus
    include Interactors::Errors

    def self.perform!(efforts, options = {})
      new(efforts, options).perform!
    end

    def initialize(efforts, options = {})
      ArgsValidator.validate(subject: efforts, params: options, exclusive: [:times_container, :calc_model], class: self)
      @efforts = efforts && Array.wrap(efforts)
      @times_container = options[:times_container] || SegmentTimesContainer.new(calc_model: options[:calc_model] || :stats)
      @errors = []
    end

    def perform!
      ActiveRecord::Base.transaction do
        import_resources(SplitTime, changed_split_times, [:data_status])
        import_resources(Effort, changed_efforts, [:data_status])
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message, changed_resources)
    end

    private

    attr_reader :efforts, :times_container, :errors

    def import_resources(model, resources, update_fields)
      result = model.import(resources, on_duplicate_key_update: update_fields, validate: false)
      unless result.failed_instances.empty?
        result.failed_instances.each { |resource| errors << resource_error_object(resource) }
      end
    end

    def changed_resources
      @changed_resources ||= status_responses.map(&:resources).flatten
    end

    def changed_efforts
      changed_resources.select { |resource| resource.is_a?(Effort) }
    end

    def changed_split_times
      changed_resources.select { |resource| resource.is_a?(SplitTime) }
    end

    def status_responses
      @status_responses ||= efforts.map { |effort| Interactors::SetEffortStatus.perform(effort, times_container: times_container) }
    end

    def message
      if errors.empty?
        "Updated #{changed_efforts.size} efforts and #{changed_split_times.size} split times. "
      else
        "Could not update efforts. "
      end
    end
  end
end
