class RaceShowView

  attr_reader :race, :courses, :events
  delegate :id, :name, :description, :stewards, to: :race

  def initialize(race, params)
    @race = race
    @params = params
    @events = race.events.select_with_params(@params[:search]).to_a
    @courses = Course.used_for_race(race)
  end

  def events_count
    events ? events.count : 0
  end

  def courses_count
    courses ? courses.count : 0
  end

  def stewards_count
    stewards ? stewards.count : 0
  end

  def view_text
    case params[:view]
      when 'courses'
        'courses'
      when 'stewards'
        'stewards'
      else
        'events'
    end
  end

end
