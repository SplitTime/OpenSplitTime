# frozen_string_literal: true

module Interactors
  class DuplicateCourse
    include ActionView::Helpers::TextHelper

    def self.perform!(args)
      new(args).perform!
    end

    def initialize(args)
      ArgsValidator.validate(params: args, required: [:course, :new_name], exclusive: [:course, :new_name, :organization], class: self.class)
      @course = args[:course]
      @new_name = args[:new_name]
      @organization = args[:organization]
      @errors = []
    end

    def perform!
      new_course = Course.new(course.dup.attributes.merge(name: new_name))
      new_course.organization = organization if organization
      course.splits.each { |split| new_course.splits.new(split.dup.attributes) }

      unless new_course.save
        errors << Interactors::Errors.resource_error_object(course)
      end

      Interactors::Response.new(errors, message, {course: new_course})
    end

    private

    attr_reader :course, :new_name, :organization, :errors

    def message
      if errors.present?
        "Unable to duplicate course"
      else
        "Duplicated #{course.name} as #{new_name} with #{course.splits.size} splits"
      end
    end
  end
end
