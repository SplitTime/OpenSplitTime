module Interactors
  class SaveValidResources
    include Interactors::Errors

    def self.perform(response)
      new(response).perform
    end

    def initialize(response)
      @response = response
      @errors = []
      @resources = {saved: [], unsaved: []}
    end

    def perform
      ActiveRecord::Base.transaction do
        response.resources[:valid].each { |resource| save_and_categorize(resource) }
        raise ActiveRecord::Rollback if errors.present?
      end
      Interactors::Response.new(errors, message, resources)
    end

    private

    attr_reader :response, :errors, :resources

    def save_and_categorize(resource)
      if resource.save
        resources[:saved] << resource
      else
        resources[:unsaved] << resource
        errors << resource_error_object(resource)
      end
    end

    def message
      errors.present? ? "No records were saved" : "#{response.resources.size} records were saved"
    end
  end
end
