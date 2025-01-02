class CourseGroupFinisherPresenter < ::SimpleDelegator
  delegate :course_group, :full_name, to: :course_group_finisher
  delegate :person, :full_name, to: :course_group_finisher
  delegate :organization, to: :course_group
  delegate :birthdate, :full_bio, to: :person

  def initialize(course_group_finisher)
    @course_group_finisher = course_group_finisher
  end

  def course_group_best_efforts
    @course_group_best_efforts ||=
      begin
        efforts = ::BestEffortSegment.for_courses(course_group.courses)
                                     .full_course
                                     .with_overall_gender_age_and_event_rank
        BestEffortSegment.from(efforts, :best_effort_segments).where(person: course_group_finisher.person_id)
      end
  end

  def organization_name
    organization.name
  end

  private

  attr_reader :course_group_finisher
end
