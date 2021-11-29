# frozen_string_literal: true

module Interactors
  class MergePeople
    include Interactors::Errors
    PERSONAL_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone, :photo]

    def self.perform!(survivor, target)
      new(survivor, target).perform!
    end

    def initialize(survivor, target)
      @survivor = survivor
      @target = target
      @errors = []
    end

    def perform!
      target.efforts.each { |effort| survivor.efforts << effort }
      Interactors::PullAttributes.perform(target, survivor, PERSONAL_ATTRIBUTES)
      Interactors::PullGeoAttributes.perform(target, survivor)
      save_changes
      Interactors::Response.new(errors, response_message, {survivor: survivor})
    end

    private

    attr_reader :survivor, :target, :errors

    def save_changes
      ActiveRecord::Base.transaction do
        if survivor.save
          unless target.destroy
            errors << resource_error_object(target)
          end
        else
          errors << resource_error_object(survivor)
        end
        raise ActiveRecord::Rollback if errors.present?
      end
    end

    def response_message
      errors.present? ? "#{target.full_name} could not be merged into #{survivor.full_name}" : "#{target.full_name} was merged into #{survivor.full_name}"
    end
  end
end
