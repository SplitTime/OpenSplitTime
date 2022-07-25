# frozen_string_literal: true

class SyncTrackPointsJob < ApplicationJob
  queue_as :default

  def perform(course_id)
    course = ::Course.find_by(id: course_id)
    return if course.nil?

    ::Interactors::SetTrackPoints.perform!(course)
  end
end
