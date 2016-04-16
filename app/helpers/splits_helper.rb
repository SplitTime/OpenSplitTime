module SplitsHelper

  def set_course_and_event
    if params[:event_id]
      @event = Event.find(params[:event_id])
      @course = @event.course
    else
      @course = Course.find(params[:course_id]) if params[:course_id]
    end
  end

end