class SyncTrackPointsJob < ApplicationJob
  self.queue_adapter = :solid_queue
  queue_as :solid_default

  def perform(course_id)
    course = ::Course.find_by(id: course_id)
    return if course.nil?

    ::Interactors::SetTrackPoints.perform!(course)
  end
end
