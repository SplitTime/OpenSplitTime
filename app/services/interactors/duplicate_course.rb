module Interactors
  class DuplicateCourse
    include ::ActionView::Helpers::TextHelper
    include ::Interactors::Errors

    def self.perform!(course:, new_name:, organization: nil)
      new(course: course, new_name: new_name, organization: organization).perform!
    end

    def initialize(course:, new_name:, organization: nil)
      raise ArgumentError, "duplicate_course must include course" unless course
      raise ArgumentError, "duplicate_course must include new_name" unless new_name

      @course = course
      @new_name = new_name
      @organization = organization
      @errors = []
    end

    def perform!
      new_course = ::Course.new(course.dup.attributes.merge(name: new_name))
      new_course.organization = organization if organization
      course.splits.each { |split| new_course.splits.new(split.dup.attributes) }

      errors << resource_error_object(course) unless new_course.save

      ::Interactors::Response.new(errors, message, { course: new_course })
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
